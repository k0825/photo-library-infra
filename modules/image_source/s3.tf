resource "aws_s3_bucket" "photo_library" {
  bucket = var.image_source_name
}

resource "aws_s3_bucket_public_access_block" "photo_library" {
  bucket = aws_s3_bucket.photo_library.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
