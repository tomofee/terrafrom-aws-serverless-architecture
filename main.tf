terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

######################################
# DynamoDB Table
######################################
resource "aws_dynamodb_table" "todo" {
  name         = "TodoTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = var.project
  }
}

######################################
# IAM Role for Lambda
######################################
resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cw" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

######################################
# Lambda Function
######################################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "todo_lambda" {
  function_name = "${var.project}-lambda"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.todo.name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_cw]
}

######################################
# API Gateway
######################################
resource "aws_api_gateway_rest_api" "todo_api" {
  name = "${var.project}-api"
}

resource "aws_api_gateway_resource" "todo_resource" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  parent_id   = aws_api_gateway_rest_api.todo_api.root_resource_id
  path_part   = "todo"
}

resource "aws_api_gateway_method" "todo_any" {
  rest_api_id   = aws_api_gateway_rest_api.todo_api.id
  resource_id   = aws_api_gateway_resource.todo_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "todo_integration" {
  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  resource_id = aws_api_gateway_resource.todo_resource.id
  http_method = aws_api_gateway_method.todo_any.http_method
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.todo_lambda.invoke_arn
  integration_http_method = "POST"
}

######################################
# Lambda Permission (API → Lambda)
######################################
resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.todo_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

######################################
# Deployment & Stage
######################################
resource "aws_api_gateway_deployment" "todo_deploy" {
  depends_on = [aws_api_gateway_integration.todo_integration]

  rest_api_id = aws_api_gateway_rest_api.todo_api.id
  stage_name  = "dev"
}

