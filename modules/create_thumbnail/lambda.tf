resource "aws_lambda_function" "create_thumbnail" {
  filename         = "./build/lambda_function_payload.zip"
  function_name    = "create_thumbnail"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_handler"
  source_code_hash = data.archive_file.create_thumbnail.output_base64sha256
  runtime          = "python3.10"
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
      rm -rf ${path.module}/lambda/build/layer
      mkdir -p ${path.module}/lambda/build/layer
      pip install -r ${path.module}/lambda/src/requirements.txt -t ${path.module}/lambda/build/layer
    EOF
  }
}

data "archive_file" "layer" {
  type        = "zip"
  source_file = "${path.module}/lambda/build/layer"
  output_path = "${path.module}/lambda/build/layer.zip"
}

resource "aws_lambda_layer_version" "layer" {
  layer_name          = "create_thumbnail_layer"
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = ["python3.10"]
}