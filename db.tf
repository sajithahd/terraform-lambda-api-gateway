
// define dynamo db
resource "aws_dynamodb_table" "db_estore" {
  name = "db_estore"
  hash_key = "productId"
  billing_mode = "PROVISIONED"
  read_capacity = 5
  write_capacity = 5
  attribute {
    name = "productId"
    type = "S"
  }
}
