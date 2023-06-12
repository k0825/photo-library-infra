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
        "arn:aws:s3:::${bucket_name}/*",
        "arn:aws:s3:::${bucket_name}"
      ]
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "dynamodb:putItem"
      ],
      "Resource" : [
        "arn:aws:dynamodb:ap-northeast-1:${account_id}:table/${table_name}"
      ]
    }
  ]
}