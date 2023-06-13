resource "aws_iam_role" "lambda_role" {
  name               = "create-thumbnail-role"
  assume_role_policy = file("${path.module}/policies/lambda_assume_role.json")
}

resource "aws_iam_policy" "lambda_policy" {
  name = "create-thumbnail-policy"
  policy = templatefile("${path.module}/policies/lambda_policy.json.tpl",
    {
      table_name  = var.mapping_table_name,
      bucket_name = var.photo_library_name,
      account_id  = local.account_id
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
