{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Action" : [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource" : "*"
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "s3:*"
      ],
      "Resource" : [
        "arn:aws:s3:::${var.bucket_name}/*",
        "arn:aws:s3:::${var.bucket_name}"
      ]
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "dynamodb:putItem"
      ],
      "Resource" : [
        "arn:aws:dynamodb:ap-northeast-1:${var.account_id}:table/${var.table_name}"
      ]
    }
  ]
}