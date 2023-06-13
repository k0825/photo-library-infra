resource "aws_sqs_queue" "queue" {
  name                       = "create_thumbnail_queue"
  message_retention_seconds  = 60 * 60 * 24
  visibility_timeout_seconds = 900 + 60
  delay_seconds              = 0
  receive_wait_time_seconds  = 0
  max_message_size           = 262144
}
