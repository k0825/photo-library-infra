resource "aws_dynamodb_table" "mapping_table" {
  name         = "${var.image_source_name}_mapping_table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
