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

//locals {
//  lambda_dist =
//}

data "archive_file" "lambda_estore_dist" {
  type = "zip"

  source_dir = "${path.module}/estore"
  output_path = "${path.module}/estore.zip"
}

resource "aws_s3_bucket_object" "estore_bucket_object" {
  bucket = aws_s3_bucket.estore_bucket.id

  key = "estore.zip"
  source = data.archive_file.lambda_estore_dist.output_path

  etag = filemd5(data.archive_file.lambda_estore_dist.output_path)
}


resource "aws_lambda_function" "lambda_estore" {
  function_name = "estore"

  s3_bucket = aws_s3_bucket.estore_bucket.id
  s3_key = aws_s3_bucket_object.estore_bucket_object.key

  runtime = "nodejs12.x"
  handler = "estore.handler"

  source_code_hash = data.archive_file.lambda_estore_dist.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "log-estore" {
  name = "/aws/lambda/${aws_lambda_function.lambda_estore.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



resource "aws_apigatewayv2_api" "api-estore" {
  name          = "serverless_estore_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "stage-estore" {
  api_id = aws_apigatewayv2_api.api-estore.id

  name        = "serverless_estore_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    }
    )
  }
}

resource "aws_apigatewayv2_integration" "estore" {
  api_id = aws_apigatewayv2_api.api-estore.id

  integration_uri    = aws_lambda_function.lambda_estore.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "estore" {
  api_id = aws_apigatewayv2_api.api-estore.id

  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.estore.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.api-estore.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_estore.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api-estore.execution_arn}/*/*"
}
