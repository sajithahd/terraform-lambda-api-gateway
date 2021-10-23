
resource "aws_s3_bucket" "estore_bucket" {
  bucket = "sj-estore-bucket"

  acl = "private"
  force_destroy = true
}

// dist making
data "archive_file" "lambda_estore_dist" {
  type = "zip"

  source_dir = "${path.module}/estore"
  output_path = "${path.module}/dist/estore.zip"
}

// s3 bucket making
resource "aws_s3_bucket_object" "estore_bucket_object" {
  bucket = aws_s3_bucket.estore_bucket.id

  key = "estore.zip"
  source = data.archive_file.lambda_estore_dist.output_path

  etag = filemd5(data.archive_file.lambda_estore_dist.output_path)
}
