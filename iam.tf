
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
  role = aws_iam_role.role_lambda_exec.id
  policy = file("./iam/policy.json")
}


resource "aws_iam_role" "role_lambda_db" {
  name = "role_serverless_lambda_db"
  assume_role_policy = file("./iam/assume_role_policy.json")
}
