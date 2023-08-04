resource "aws_s3_bucket" "failure_reports_bucket" {
  bucket = "failure-reports-bucket"
}

data "archive_file" "failure_report_events_lambda_code" {
 type        = "zip"
 source_dir  = "${path.module}/Failure Report Events Lambda/"
 output_path = "${path.module}/Failure Report Events Lambda/Failure Report Events Lambda.zip"
}



resource "aws_lambda_function" "failure_report_events_lambda" {
 filename                       = "${path.module}/Failure Report Events Lambda/Failure Report Events Lambda.zip"
 function_name                  = "failure-report-events-lambda"
 role                           = aws_iam_role.root_role.arn
 handler                        = "index.handler"
 runtime                        = "python3.8"

 environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.failure_report_sns_topic.arn
    }
  }
}




resource "aws_lambda_permission" "s3_failure_report_events_lambda_permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failure_report_events_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.failure_reports_bucket.arn
}

resource "aws_s3_bucket_notification" "s3_failure_report_events_lambda_trigger" {
  bucket = aws_s3_bucket.failure_reports_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.failure_report_events_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_failure_report_events_lambda_permission]
}


resource "aws_sns_topic" "failure_report_sns_topic" {
  name = "failure-report-sns-topic"
}


resource "aws_sns_topic_subscription" "failure_report_sns_sqs_subscription" {
  topic_arn = aws_sns_topic.failure_report_sns_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.failure_report_sqs_queue.arn
}


resource "aws_sqs_queue" "failure_report_sqs_queue" {
  name = "failure-report-sqs"
}

resource "aws_sqs_queue_policy" "failure_report_sqs_queue_policy" {
  queue_url = aws_sqs_queue.failure_report_sqs_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Allow-SNS-SendMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.failure_report_sqs_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.failure_report_sns_topic.arn
          }
        }
      }
    ]
  })
}




resource "aws_lambda_permission" "failure_report_sns_publish_permission" {
  statement_id  = "AllowSNSTopicPublish"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failure_report_events_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.failure_report_sns_topic.arn
}



data "archive_file" "failure_report_handler_lambda_code" {
  type        = "zip"
  source_dir  = "${path.module}/Failure Report Handler Lambda/" 
  output_path = "${path.module}/Failure Report Handler Lambda/Failure Report Handler Lambda.zip"
}



resource "aws_lambda_function" "failure_report_handler_lambda" {
  filename      = "${path.module}/Failure Report Handler Lambda/Failure Report Handler Lambda.zip"
  function_name = "failure-report-handler-lambda"
  role          = aws_iam_role.root_role.arn
  handler       = "index.handler"  # Assuming "index" is the filename and "handler" is the exported function in the Node.js code
  runtime       = "nodejs18.x"  

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.failure_report_sqs_queue.url
      ASSETS_TABLE  = aws_dynamodb_table.assets_table.name
    }
  }
}


resource "aws_lambda_event_source_mapping" "failure_report_handler_lambda_trigger" {
  event_source_arn  = aws_sqs_queue.failure_report_sqs_queue.arn
  function_name     = aws_lambda_function.failure_report_handler_lambda.function_name
  batch_size        = 1
}
