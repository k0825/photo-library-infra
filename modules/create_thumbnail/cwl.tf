resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/create_thumbnail"
  retention_in_days = 14
}
