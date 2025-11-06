# Lambda functions

# Archive Lambda source code
data "archive_file" "lambda_zip" {
  for_each    = local.lambda_functions
  type        = "zip"
  source_file = "${path.module}/lambda-functions/${each.value}/lambda_function.py"
  output_path = "${path.module}/lambda-functions/${each.value}.zip"
}

# API Ingest Lambda
resource "aws_lambda_function" "api_ingest" {
  filename      = data.archive_file.lambda_zip["api_ingest"].output_path
  function_name = local.lambda_functions.api_ingest
  role          = aws_iam_role.api_ingest.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip["api_ingest"].output_base64sha256

  environment {
    variables = {
      EVENTBUS_NAME = aws_cloudwatch_event_bus.dns_checks.name
      MAX_TARGETS   = "10"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs["api_ingest"]
  ]

  tags = local.tags
}

# DNS Resolver Lambda
resource "aws_lambda_function" "dns_resolver" {
  filename      = data.archive_file.lambda_zip["dns_resolver"].output_path
  function_name = local.lambda_functions.dns_resolver
  role          = aws_iam_role.dns_resolver.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip["dns_resolver"].output_base64sha256

  environment {
    variables = {
      EVENTBUS_NAME = aws_cloudwatch_event_bus.dns_checks.name
      DNS_TIMEOUT   = "5"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs["dns_resolver"]
  ]

  tags = local.tags
}

# HTTP Prober Lambda
resource "aws_lambda_function" "http_prober" {
  filename      = data.archive_file.lambda_zip["http_prober"].output_path
  function_name = local.lambda_functions.http_prober
  role          = aws_iam_role.http_prober.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip["http_prober"].output_base64sha256

  environment {
    variables = {
      EVENTBUS_NAME = aws_cloudwatch_event_bus.dns_checks.name
      HTTP_TIMEOUT  = "10"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs["http_prober"]
  ]

  tags = local.tags
}

# HTTPS Prober Lambda
resource "aws_lambda_function" "https_prober" {
  filename      = data.archive_file.lambda_zip["https_prober"].output_path
  function_name = local.lambda_functions.https_prober
  role          = aws_iam_role.https_prober.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip["https_prober"].output_base64sha256

  environment {
    variables = {
      EVENTBUS_NAME = aws_cloudwatch_event_bus.dns_checks.name
      HTTPS_TIMEOUT = "10"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs["https_prober"]
  ]

  tags = local.tags
}

# Aggregator Lambda
resource "aws_lambda_function" "aggregator" {
  filename      = data.archive_file.lambda_zip["aggregator"].output_path
  function_name = local.lambda_functions.aggregator
  role          = aws_iam_role.aggregator.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip["aggregator"].output_base64sha256

  environment {
    variables = {
      EVENTBUS_NAME  = aws_cloudwatch_event_bus.dns_checks.name
      DYNAMODB_TABLE = aws_dynamodb_table.validations.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs["aggregator"]
  ]

  tags = local.tags
}

# Status API Lambda
resource "aws_lambda_function" "status_api" {
  filename      = data.archive_file.lambda_zip["status_api"].output_path
  function_name = local.lambda_functions.status_api
  role          = aws_iam_role.status_api.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_zip["status_api"].output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.validations.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs["status_api"]
  ]

  tags = local.tags
}

# IP Authorizer Lambda
resource "aws_lambda_function" "ip_authorizer" {
  filename      = data.archive_file.lambda_zip["ip_authorizer"].output_path
  function_name = local.lambda_functions.ip_authorizer
  role          = aws_iam_role.ip_authorizer.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 5

  source_code_hash = data.archive_file.lambda_zip["ip_authorizer"].output_base64sha256

  environment {
    variables = {
      ALLOWED_IPS = "${trimspace(data.http.my_public_ip.response_body)}/32"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs["ip_authorizer"]
  ]

  tags = local.tags
}

# Lambda permissions for EventBridge
resource "aws_lambda_permission" "dns_resolver" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dns_resolver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.validation_requested.arn
}

resource "aws_lambda_permission" "http_prober" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http_prober.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dns_resolved.arn
}

resource "aws_lambda_permission" "https_prober" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.https_prober.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dns_resolved.arn
}

resource "aws_lambda_permission" "aggregator" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aggregator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.aggregator_events.arn
}
