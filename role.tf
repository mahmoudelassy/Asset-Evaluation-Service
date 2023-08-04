
resource "aws_iam_role" "root_role" {
  name = "root-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "root_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.root_role.name
}

resource "aws_iam_role_policy_attachment" "root_role_logs_policy_attachment" {
  role       = aws_iam_role.root_role.name
  policy_arn = aws_iam_policy.root_role_logs_policy.arn
}

resource "aws_iam_policy" "root_role_logs_policy" {
  name        = "root-role-logs-policy"
  description = "Policy for log-related actions"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "logs:CreateLogGroup",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
     {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.assets_sns_topic.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.assets_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:ReceiveMessage",
      "Resource": "${aws_sqs_queue.assets_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:DeleteMessage",
      "Resource": "${aws_sqs_queue.assets_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:GetQueueAttributes",
      "Resource": "${aws_sqs_queue.assets_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "dynamodb:PutItem",
      "Resource": "${aws_dynamodb_table.assets_table.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.failure_report_sns_topic.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.failure_report_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:ReceiveMessage",
      "Resource": "${aws_sqs_queue.failure_report_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:DeleteMessage",
      "Resource": "${aws_sqs_queue.failure_report_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:GetQueueAttributes",
      "Resource": "${aws_sqs_queue.failure_report_sqs_queue.arn}"
    }
  ]
}
EOF
}
