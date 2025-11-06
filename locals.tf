locals {
  project_name = var.project_name
  region       = data.aws_region.current.region

  # Common tags
  tags = {
    Project     = local.project_name
    ManagedBy   = "Terraform"
    Environment = "demo"
  }

  # Lambda function names
  lambda_functions = {
    api_ingest    = "${local.project_name}-api-ingest"
    dns_resolver  = "${local.project_name}-dns-resolver"
    http_prober   = "${local.project_name}-http-prober"
    https_prober  = "${local.project_name}-https-prober"
    aggregator    = "${local.project_name}-aggregator"
    status_api    = "${local.project_name}-status-api"
    ip_authorizer = "${local.project_name}-ip-authorizer"
  }

  # EventBridge bus name
  eventbus_name = "${local.project_name}-bus"

  # DynamoDB table name
  dynamodb_table_name = "${local.project_name}-validations"
}

# Build frontend before deployment
resource "null_resource" "frontend_build" {
  triggers = {
    api_endpoint = aws_apigatewayv2_api.main.api_endpoint
    package_json = filemd5("${path.module}/frontend/package.json")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/frontend
      if [ ! -d "node_modules" ]; then
        npm install
      fi
      VITE_API_ENDPOINT=${aws_apigatewayv2_api.main.api_endpoint} npm run build
    EOT
  }
}
