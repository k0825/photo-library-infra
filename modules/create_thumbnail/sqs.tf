resource "aws_sqs_queue" "queue" {
  name                       = local.create_thumbnail_queue
  message_retention_seconds  = 60 * 60 * 24
  visibility_timeout_seconds = 900 + 60
  delay_seconds              = 0
  receive_wait_time_seconds  = 0
  max_message_size           = 262144
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn,
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy = templatefile("${path.module}/policies/sqs_policy.json", {
    account_id     = local.account_id
    sqs_queue_name = aws_sqs_queue.queue.name
    bucket_name    = var.photo_library_name
  })
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name = "${local.create_thumbnail_queue}-dlq"
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = ["arn:aws:sqs:ap-northeast-1:${local.account_id}:${local.create_thumbnail_queue}"]
  })

}
