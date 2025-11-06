output "api_gateway_url" {
  description = "API Gateway HTTP API endpoint URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "frontend_url" {
  description = "S3 website endpoint URL for frontend (HTTP only)"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.validations.name
}

output "eventbridge_bus_name" {
  description = "EventBridge custom bus name"
  value       = aws_cloudwatch_event_bus.dns_checks.name
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.id
}
