resource "aws_lambda_function" "create_thumbnail" {
  filename         = "${path.module}/lambda/build/lambda_function_payload.zip"
  function_name    = "create_thumbnail"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.create_thumbnail.output_base64sha256
  runtime          = "python3.10"
  layers           = [aws_lambda_layer_version.layer.arn]
  timeout          = 900
  memory_size      = 10240

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
      rm -rf ${path.module}/lambda/build/layer/python
      mkdir -p ${path.module}/lambda/build/layer/python
      pip install --platform manylinux2014_x86_64 \
            -r ${path.module}/lambda/src/requirements.txt \
            -t ${path.module}/lambda/build/layer/python \
            --only-binary=:all: --upgrade
    EOF
  }
}

data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/build/layer"
  output_path = "${path.module}/lambda/build/layer.zip"

  depends_on = [null_resource.layer]
}

resource "aws_lambda_layer_version" "layer" {
  layer_name          = "create_thumbnail_layer"
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = ["python3.10"]
}

resource "aws_lambda_event_source_mapping" "sqs" {
  function_name                      = aws_lambda_function.create_thumbnail.arn
  event_source_arn                   = aws_sqs_queue.queue.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5

  lifecycle {
    create_before_destroy = true
  }
}
