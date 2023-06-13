data "aws_caller_identity" "current" {}

locals {
  account_id             = data.aws_caller_identity.current.account_id
  create_thumbnail_queue = "create-thumbnail-queue"

}
