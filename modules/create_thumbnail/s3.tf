resource "aws_s3_bucket_notification" "notifier" {
  bucket = var.photo_library_name

  queue {
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "original/"
  }
}
