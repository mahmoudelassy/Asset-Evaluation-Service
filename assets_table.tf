resource "aws_dynamodb_table" "assets_table" {
  name           = "assets-table"
  billing_mode   = "PAY_PER_REQUEST"

  attribute {
    name = "PartitionKey"
    type = "S"
  }

  attribute {
    name = "SortKey"
    type = "S"
  }

  hash_key       = "PartitionKey"   
  range_key      = "SortKey"       
}

resource "aws_lambda_permission" "assets_handler_dynamodb_permission" {
  statement_id  = "AllowDynamoDBWrite"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.assets_handler_lambda.function_name
  principal     = "dynamodb.amazonaws.com"
  source_arn    = aws_dynamodb_table.assets_table.arn
}

resource "aws_lambda_permission" "failure_report_handler_dynamodb_permission" {
  statement_id  = "AllowDynamoDBWrite"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failure_report_handler_lambda.function_name
  principal     = "dynamodb.amazonaws.com"
  source_arn    = aws_dynamodb_table.assets_table.arn
}

resource "aws_iam_policy" "assets_handler_lambda_policy" {
  name        = "assets-handler-lambda-policy"
  description = "Policy for assets_handler_lambda role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "dynamodb:PutItem",
      "Resource": "${aws_dynamodb_table.assets_table.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "failure_report_handler_lambda_policy" {
  name        = "failure-report-handler-lambda-policy"
  description = "Policy for failure_report_handler_lambda role"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "dynamodb:PutItem",
      "Resource": "${aws_dynamodb_table.assets_table.arn}"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "assets_handler_lambda_dynamodb_attachment" {
  policy_arn = aws_iam_policy.assets_handler_lambda_policy.arn
  role       = aws_iam_role.root_role.name
}

resource "aws_iam_role_policy_attachment" "failure_report_handler_lambda_dynamodb_attachment" {
  policy_arn = aws_iam_policy.failure_report_handler_lambda_policy.arn
  role       = aws_iam_role.root_role.name
}



