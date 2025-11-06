# CloudWatch Log Groups for Lambda functions

resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each          = local.lambda_functions
  name              = "/aws/lambda/${each.value}"
  retention_in_days = 1

  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.project_name}"
  retention_in_days = 7

  tags = local.tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", color = "#1f77b4" }],
            [".", "Errors", { stat = "Sum", color = "#d62728" }],
            [".", "Duration", { stat = "Average", color = "#2ca02c" }]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "Lambda Function Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum", color = "#1f77b4" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum", color = "#d62728" }]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "DynamoDB Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarms for error rates
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each            = local.lambda_functions
  alarm_name          = "${each.value}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This metric monitors lambda function errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  tags = local.tags
}
