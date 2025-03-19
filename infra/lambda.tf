locals {
  lambda_handler = "main.handler"
  lambda_runtime = "python3.9"

  lambda_root       = "${path.module}/../lambda"
  lambda_layer_root = "${local.lambda_root}/layer"
}

resource "aws_iam_role" "lambda_exec" {
  name = "role-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_exec" {
  name        = "policy-lambda-exec"
  description = "Allow lambda to write logs to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda-write-s3" {
  name        = "policy-lambda-write-s3"
  description = "Allow lambda to write to S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:*"],
        Resource = [
          "arn:aws:s3:::${var.raw_data_bucket}/*",
          "arn:aws:s3:::${var.raw_data_bucket}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec.arn
}

resource "aws_iam_role_policy_attachment" "lambda-write-s3" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda-write-s3.arn
}

resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = "pip install --quiet --quiet --no-cache-dir --requirement ${local.lambda_root}/youtube-trends-scraper/requirements.txt --target ${local.lambda_root}/layer/python"
  }

  triggers = {
    # Use this to force an update of pip dependencies
    #always_run   = timestamp()
    requirements = filemd5("${local.lambda_root}/youtube-trends-scraper/requirements.txt")
  }
}

data "archive_file" "lambda-layer" {
  depends_on = [null_resource.pip_install]
  type        = "zip"
  source_dir  = "${path.module}/../lambda/layer"
  output_path = "${path.module}/../lambda/layer.zip"
}

resource "aws_lambda_layer_version" "layer" {
  layer_name       = "lambda-youtube-trends-scraper-layer"
  filename         = data.archive_file.lambda-layer.output_path
  source_code_hash = data.archive_file.lambda-layer.output_base64sha256
  compatible_runtimes = [local.lambda_runtime]

  lifecycle {
    create_before_destroy = true
  }
}

data "archive_file" "lambda-function" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/youtube-trends-scraper"
  output_path = "${path.module}/../lambda/youtube-trends-scraper.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "lambda-youtube-trends-scraper"
  role          = aws_iam_role.lambda_exec.arn

  timeout = 10
  handler = local.lambda_handler
  runtime = local.lambda_runtime

  source_code_hash = data.archive_file.lambda-function.output_base64sha256
  filename         = data.archive_file.lambda-function.output_path
  layers = [aws_lambda_layer_version.layer.arn]

  environment {
    variables = {
      YOUTUBE_DATA_API_KEY = var.youtube_api_key
      RAW_DATA_BUCKET      = var.raw_data_bucket
      COUNTRY_CODES        = var.country_codes
    }
  }
}