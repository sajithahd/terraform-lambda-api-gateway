# Output value definitions

output "lambda_bucket_name" {
  description = "S3 Bucket used to store lambda function code."
  value = aws_s3_bucket.estore_bucket.id
}
