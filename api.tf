
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
