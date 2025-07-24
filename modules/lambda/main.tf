#############################################################
# modules/lambda/main.tf  – revised
#
# Uses an **existing** IAM role (default name "LabRole") instead of
# creating a new one. The caller can override `existing_role_name` if
# needed.
#############################################################

########################################
# 1. Locate the pre‑created IAM role
########################################

data "aws_iam_role" "lambda_exec" {
  name = var.existing_role_name  # defaults to "LabRole"
}

########################################
# 2. Package the Python handler into a ZIP
########################################

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.handler_file     # path to lambda_function.py
  output_path = "${path.module}/lambda.zip"
}

########################################
# 3. Lambda function
########################################

resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = data.aws_iam_role.lambda_exec.arn   # << existing role

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }

  # ensure the ZIP is created before upload
  depends_on = [data.archive_file.lambda_zip]
}

########################################
# 4. Public Function URL with open CORS
########################################

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}