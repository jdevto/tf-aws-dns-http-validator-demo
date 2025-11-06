# API Gateway HTTP API

resource "aws_apigatewayv2_api" "main" {
  name          = "${local.project_name}-api"
  protocol_type = "HTTP"
  description   = "DNS and HTTP validation API"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key"]
    max_age       = 300
  }

  # Note: IP restriction is implemented via Lambda authorizer

  tags = local.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [
    aws_cloudwatch_log_group.api_gateway
  ]

  tags = local.tags
}

# Lambda authorizer for IP restriction
resource "aws_apigatewayv2_authorizer" "ip_authorizer" {
  api_id                            = aws_apigatewayv2_api.main.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.ip_authorizer.invoke_arn
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = false
  name                              = "${local.project_name}-ip-authorizer"

  depends_on = [
    aws_lambda_permission.ip_authorizer
  ]
}

resource "aws_lambda_permission" "ip_authorizer" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ip_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# POST /check route
resource "aws_apigatewayv2_route" "check" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "POST /check"
  authorizer_id      = aws_apigatewayv2_authorizer.ip_authorizer.id
  authorization_type = "CUSTOM"

  target = "integrations/${aws_apigatewayv2_integration.check.id}"
}

resource "aws_apigatewayv2_integration" "check" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = aws_lambda_function.api_ingest.invoke_arn
  integration_method = "POST"
}

resource "aws_lambda_permission" "api_ingest" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_ingest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# GET /status route
resource "aws_apigatewayv2_route" "status" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /status"

  target = "integrations/${aws_apigatewayv2_integration.status.id}"
}

resource "aws_apigatewayv2_integration" "status" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = aws_lambda_function.status_api.invoke_arn
  integration_method = "POST"
}

resource "aws_lambda_permission" "status_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# GET /recent route
resource "aws_apigatewayv2_route" "recent" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /recent"

  target = "integrations/${aws_apigatewayv2_integration.recent.id}"
}

resource "aws_apigatewayv2_integration" "recent" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = aws_lambda_function.status_api.invoke_arn
  integration_method = "POST"
}
