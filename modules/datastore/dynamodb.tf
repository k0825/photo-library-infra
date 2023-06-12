resource "aws_dynamodb_table" "mapping_table" {
  name         = replace("${var.photo_library_name}_mapping_table", "-", "_")
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
