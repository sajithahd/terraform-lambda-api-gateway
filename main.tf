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



// config logs
resource "aws_cloudwatch_log_group" "log_estore" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function_estore.function_name}"

  retention_in_days = 30
}

