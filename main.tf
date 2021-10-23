terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.63.0"
    }

    archive = {
      source = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}


resource "aws_s3_bucket" "estore_bucket" {
  bucket = "sj-estore-bucket"

  acl = "private"
  force_destroy = true
}

// dist making
data "archive_file" "lambda_estore_dist" {
  type = "zip"

  source_dir = "${path.module}/estore"
  output_path = "${path.module}/estore.zip"
}

// s3 bucket making
resource "aws_s3_bucket_object" "estore_bucket_object" {
  bucket = aws_s3_bucket.estore_bucket.id

  key = "estore.zip"
  source = data.archive_file.lambda_estore_dist.output_path

  etag = filemd5(data.archive_file.lambda_estore_dist.output_path)
}

// assume role define
resource "aws_iam_role" "role_lambda_exec" {
  name = "role_serverless_lambda"
  assume_role_policy = file("iam/assume_role_policy.json")
}

// attach policy to the role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role = aws_iam_role.role_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.role_lambda_db.id

  policy = file("./iam/policy.json")
}


resource "aws_iam_role" "role_lambda_db" {
  name = "role_serverless_lambda_db"
  assume_role_policy = file("./iam/assume_role_policy.json")
}

// lambda function creation
resource "aws_lambda_function" "lambda_function_estore" {
  function_name = "l-estore"

  s3_bucket = aws_s3_bucket.estore_bucket.id
  s3_key = aws_s3_bucket_object.estore_bucket_object.key

  handler = "estore.handler"
  runtime = "nodejs12.x"

  source_code_hash = data.archive_file.lambda_estore_dist.output_base64sha256
  role = aws_iam_role.role_lambda_exec.arn
}

// lambda function for db
resource "aws_lambda_function" "lambda_function_estore_db" {

  function_name = "db-estore"

  s3_bucket = aws_s3_bucket.estore_bucket.id
  s3_key = aws_s3_bucket_object.estore_bucket_object.key

  handler = "estore.dbhandler"
  runtime = "nodejs12.x"

  source_code_hash = data.archive_file.lambda_estore_dist.output_base64sha256
  role = aws_iam_role.role_lambda_db.arn
}


// config logs
resource "aws_cloudwatch_log_group" "log_estore" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function_estore.function_name}"

  retention_in_days = 30
}


// api gateway
resource "aws_apigatewayv2_api" "api_estore" {
  name = "serverless_estore_gw"
  protocol_type = "HTTP"
}

// define stages with access logs
resource "aws_apigatewayv2_stage" "stage_estore" {
  api_id = aws_apigatewayv2_api.api_estore.id

  name = "serverless_estore_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId = "$context.requestId"
      sourceIp = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      protocol = "$context.protocol"
      httpMethod = "$context.httpMethod"
      resourcePath = "$context.resourcePath"
      routeKey = "$context.routeKey"
      status = "$context.status"
      responseLength = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    }
    )
  }
}

// integrate api with uri
resource "aws_apigatewayv2_integration" "integration_estore" {
  api_id = aws_apigatewayv2_api.api_estore.id

  integration_uri = aws_lambda_function.lambda_function_estore.invoke_arn
  integration_type = "AWS_PROXY"
  integration_method = "POST"
}

// define routes with api integration
resource "aws_apigatewayv2_route" "route_estore" {
  api_id = aws_apigatewayv2_api.api_estore.id

  route_key = "GET /health"
  target = "integrations/${aws_apigatewayv2_integration.integration_estore.id}"
}

// define cloud watch log groups
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.api_estore.name}"

  retention_in_days = 30
}

// permit lambda to deal with api gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_estore.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_estore.execution_arn}/*/*"
}

// define dynamo db
resource "aws_dynamodb_table" "db_estore" {
  name = "db_estore"
  hash_key = "id"
  billing_mode = "PROVISIONED"
  read_capacity = 5
  write_capacity = 5
  attribute {
    name = "id"
    type = "S"
  }
}
