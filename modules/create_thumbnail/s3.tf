resource "aws_s3_bucket_notification" "notifier" {
  bucket = var.photo_library_name

  queue {
    queue_arn     = var.create_thumbnail_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "original/"
  }
}
