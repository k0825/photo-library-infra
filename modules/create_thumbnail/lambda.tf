resource "aws_lambda_function" "create_thumbnail" {
  filename         = "${path.module}/lambda/build/lambda_function_payload.zip"
  function_name    = "create_thumbnail"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.create_thumbnail.output_base64sha256
  runtime          = "python3.10"
  layers           = [aws_lambda_layer_version.layer.arn]

  environment {
    variables = {
      MAPPING_TABLE_NAME = var.mapping_table_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role_policy_attachment.lambda_role_policy_attachment
  ]
}

data "archive_file" "create_thumbnail" {
  type        = "zip"
  source_file = "${path.module}/lambda/src/handler.py"
  output_path = "${path.module}/lambda/build/lambda_function_payload.zip"
}

resource "null_resource" "layer" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      rm -rf ${path.module}/lambda/build/python
      mkdir -p ${path.module}/lambda/build/python
      pip install -r ${path.module}/lambda/src/requirements.txt -t ${path.module}/lambda/build/python
      zip -r ../layer.zip ${path.module}/lambda/build/python
    EOF
  }
}

resource "aws_lambda_layer_version" "layer" {
  layer_name          = "create_thumbnail_layer"
  filename            = "${path.module}/lambda/build/layer.zip"
  compatible_runtimes = ["python3.10"]
  depends_on          = [null_resource.layer]
}
