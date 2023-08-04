resource "aws_s3_bucket" "assets_bucket" {
  bucket = "assets-csv-bucket"
}

data "archive_file" "assets_events_lambda_code" {
 type        = "zip"
 source_dir  = "${path.module}/Assets Events Lambda/"
 output_path = "${path.module}/Assets Events Lambda/Assets Events Lambda.zip"
}

resource "aws_lambda_function" "assets_events_lambda" {
 filename                       = "${path.module}/Assets Events Lambda/Assets Events Lambda.zip"
 function_name                  = "assets-events-lambda"
 role                           = aws_iam_role.root_role.arn
 handler                        = "index.handler"
 runtime                        = "python3.8"

 environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.assets_sns_topic.arn
    }
  }
}

resource "aws_lambda_permission" "s3_assets_events_lambda_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.assets_events_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.assets_bucket.arn
}

resource "aws_s3_bucket_notification" "s3_assets_events_lambda_trigger" {
  bucket = aws_s3_bucket.assets_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.assets_events_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_assets_events_lambda_permission]
}

resource "aws_sns_topic" "assets_sns_topic" {
  name = "assets-sns-topic"
}

resource "aws_sns_topic_subscription" "assets_sns_sqs_subscription" {
  topic_arn = aws_sns_topic.assets_sns_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.assets_sqs_queue.arn
}

resource "aws_sqs_queue" "assets_sqs_queue" {
  name = "assets-sqs"
}

resource "aws_sqs_queue_policy" "assets_sqs_queue_policy" {
  queue_url = aws_sqs_queue.assets_sqs_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow-SNS-SendMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.assets_sqs_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.assets_sns_topic.arn
          }
        }
      }
    ]
  })
}

resource "aws_lambda_permission" "assets_sns_publish_permission" {
  statement_id  = "AllowSNSTopicPublish"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.assets_events_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.assets_sns_topic.arn
}

data "archive_file" "assets_handler_lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/Assets Handler Lambda/" 
  output_path = "${path.module}/Assets Handler Lambda/Assets Handler Lambda.zip"
}

resource "aws_lambda_function" "assets_handler_lambda" {
  filename      = "${path.module}/Assets Handler Lambda/Assets Handler Lambda.zip"
  function_name = "assets-handler-lambda"
  role          = aws_iam_role.root_role.arn
  handler       = "index.handler"  # Assuming "index" is the filename and "handler" is the exported function in the Node.js code
  runtime       = "nodejs18.x"  

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.assets_sqs_queue.url
      ASSETS_TABLE  = aws_dynamodb_table.assets_table.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "assets_handler_lambda_trigger" {
  event_source_arn  = aws_sqs_queue.assets_sqs_queue.arn
  function_name     = aws_lambda_function.assets_handler_lambda.function_name
  batch_size        = 1
}