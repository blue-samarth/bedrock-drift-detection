data "archive_file" "state_reader" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/lambda_state"
  output_path = "${path.module}/state_reader.zip"
}

resource "aws_lambda_function" "state_reader" {
  function_name    = "${local.name_prefix}-state-reader"
  role             = aws_iam_role.lambda_state_reader.arn
  handler          = "lambda_state_reader.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.state_reader.output_path
  source_code_hash = data.archive_file.state_reader.output_base64sha256
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      TF_STATE_BUCKET = local.tf_state_bucket
      TF_LOCK_TABLE   = local.dynamodb_table_name
    }
  }

  tags = {
    Name        = "lambda_terraform_state_reader"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "state_reader" {
  name              = "/aws/lambda/${aws_lambda_function.state_reader.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Component = "StateReader"
  }
}

# ────────────────────────────────────────

data "archive_file" "live_collector" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/collector"
  output_path = "${path.module}/live_collector.zip"
}

resource "aws_lambda_function" "live_collector" {
  function_name    = "${local.name_prefix}-live-collector"
  role             = aws_iam_role.lambda_live_collector.arn
  handler          = "lambda_functions_live_collector.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.live_collector.output_path
  source_code_hash = data.archive_file.live_collector.output_base64sha256
  timeout          = 60
  memory_size      = 512

  tags = {
    Name        = "live_collector_lambda"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_log_group" "live_collector" {
  name              = "/aws/lambda/${aws_lambda_function.live_collector.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Component = "LiveCollector"
  }
}

# ────────────────────────────────────────

data "archive_file" "bedrock_analyzer" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/analyzer"
  output_path = "${path.module}/bedrock_analyzer.zip"
}

resource "aws_lambda_function" "bedrock_analyzer" {
  function_name    = "${local.name_prefix}-bedrock-analyzer"
  role             = aws_iam_role.lambda_bedrock_analyzer.arn
  handler          = "lambda_bedrock_analyzer.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.bedrock_analyzer.output_path
  source_code_hash = data.archive_file.bedrock_analyzer.output_base64sha256
  timeout          = 120
  memory_size      = 1024

  # BEDROCK_MODEL_ID = anthropic.claude-3-sonnet-20240229-v1:0
  # LIVE_COLLECTOR_LAMBDA_NAME = live_collector_lambda
  # RESULTS_BUCKET = bedrock-analyzer-bucket
  # TF_STATE_LAMBDA_NAME = lambda_terraform_state_reader
  environment {
    variables = {
      LIVE_COLLECTOR_LAMBDA_NAME = aws_lambda_function.live_collector.function_name
      BEDROCK_MODEL_ID           = var.bedrock_model_id
      RESULTS_BUCKET             = local.bucket_name
      TF_STATE_LAMBDA_NAME       = aws_lambda_function.state_reader.function_name
    }
  }

  tags = {
    Name        = "${local.name_prefix}-bedrock-analyzer"
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}