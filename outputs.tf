# Output value definitions

output "lambda_bucket_name" {
  description = "S3 Bucket used to store lambda function code."
  value = aws_s3_bucket.estore_bucket.id
}

output "l_function_name" {
  description = "Lambda function"
  value = aws_lambda_function.lambda_function_estore.function_name
}

output "base_url" {
  description = "Base URL for API Gateway Stage."
  value = aws_apigatewayv2_stage.stage_estore.invoke_url
}
