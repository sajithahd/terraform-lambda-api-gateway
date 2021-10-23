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
