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

  source_dir  = "${path.module}/estore"
  output_path = "${path.module}/estore.zip"
}

resource "aws_s3_bucket_object" "lambda_estore" {
  bucket = aws_s3_bucket.estore_bucket.id

  key    = "estore.zip"
  source = data.archive_file.lambda_estore_dist.output_path

  etag = filemd5(data.archive_file.lambda_estore_dist.output_path)
}
