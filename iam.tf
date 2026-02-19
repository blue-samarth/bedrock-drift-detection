resource "aws_iam_role" "lambda_state_reader" {
  name = "${local.name_prefix}-state-reader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_state_reader_s3" {
  name = "s3-state-access"
  role = aws_iam_role.lambda_state_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.tf_state_bucket}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.tf_state_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${local.aws_region}:${data.aws_caller_identity.current.account_id}:table/${local.dynamodb_table_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_state_reader_logs" {
  role       = aws_iam_role.lambda_state_reader.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_live_collector" {
  name = "${local.name_prefix}-live-collector-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_live_collector_read" {
  name = "aws-read-access"
  role = aws_iam_role.lambda_live_collector.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVpcs",
          "s3:ListAllMyBuckets",
          "dynamodb:ListTables",
          "dynamodb:DescribeTable",
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "events:ListRules",
          "bedrock:ListFoundationModels",
          "rds:DescribeDBInstances",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_live_collector_logs" {
  role       = aws_iam_role.lambda_live_collector.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_bedrock_analyzer" {
  name = "${local.name_prefix}-bedrock-analyzer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_bedrock_analyzer_invoke" {
  name = "bedrock-invoke"
  role = aws_iam_role.lambda_bedrock_analyzer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = "arn:aws:bedrock:${local.aws_region}::foundation-model/*"
      },
      {
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.state_reader.arn,
          aws_lambda_function.live_collector.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock_analyzer_logs" {
  role       = aws_iam_role.lambda_bedrock_analyzer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "step_functions" {
  name = "${local.name_prefix}-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_lambda" {
  name = "lambda-invoke"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = [
        aws_lambda_function.state_reader.arn,
        aws_lambda_function.live_collector.arn,
        aws_lambda_function.bedrock_analyzer.arn
      ]
    }]
  })
}

resource "aws_iam_role" "eventbridge" {
  name = "${local.name_prefix}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# resource "aws_iam_role_policy" "eventbridge_stepfunctions" {
#   name = "stepfunctions-start"
#   role = aws_iam_role.eventbridge.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "states:StartExecution"
#       ]
#       Resource = 
#     }]
#   })
# }