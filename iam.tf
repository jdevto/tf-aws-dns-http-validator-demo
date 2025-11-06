# IAM roles for Lambda functions

# API Ingest Lambda Role
resource "aws_iam_role" "api_ingest" {
  name = "${local.project_name}-api-ingest-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "api_ingest" {
  name = "${local.project_name}-api-ingest-policy"
  role = aws_iam_role.api_ingest.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:*:*"
      },
      {
        Sid    = "EventBridgePutEvents"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.dns_checks.arn
      },
    ]
  })
}

# DNS Resolver Lambda Role
resource "aws_iam_role" "dns_resolver" {
  name = "${local.project_name}-dns-resolver-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "dns_resolver" {
  name = "${local.project_name}-dns-resolver-policy"
  role = aws_iam_role.dns_resolver.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:*:*"
      },
      {
        Sid    = "EventBridgePutEvents"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.dns_checks.arn
      },
    ]
  })
}

# HTTP Prober Lambda Role
resource "aws_iam_role" "http_prober" {
  name = "${local.project_name}-http-prober-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "http_prober" {
  name = "${local.project_name}-http-prober-policy"
  role = aws_iam_role.http_prober.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:*:*"
      },
      {
        Sid    = "EventBridgePutEvents"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.dns_checks.arn
      },
    ]
  })
}

# HTTPS Prober Lambda Role
resource "aws_iam_role" "https_prober" {
  name = "${local.project_name}-https-prober-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "https_prober" {
  name = "${local.project_name}-https-prober-policy"
  role = aws_iam_role.https_prober.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:*:*"
      },
      {
        Sid    = "EventBridgePutEvents"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.dns_checks.arn
      },
    ]
  })
}

# Aggregator Lambda Role
resource "aws_iam_role" "aggregator" {
  name = "${local.project_name}-aggregator-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "aggregator" {
  name = "${local.project_name}-aggregator-policy"
  role = aws_iam_role.aggregator.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:*:*"
      },
      {
        Sid    = "EventBridgePutEvents"
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = aws_cloudwatch_event_bus.dns_checks.arn
      },
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.validations.arn,
          "${aws_dynamodb_table.validations.arn}/index/*"
        ]
      }
    ]
  })
}

# Status API Lambda Role
resource "aws_iam_role" "status_api" {
  name = "${local.project_name}-status-api-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "status_api" {
  name = "${local.project_name}-status-api-policy"
  role = aws_iam_role.status_api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:*:*"
      },
      {
        Sid    = "DynamoDBReadAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Resource = [
          aws_dynamodb_table.validations.arn,
          "${aws_dynamodb_table.validations.arn}/index/*"
        ]
      }
    ]
  })
}

# IP Authorizer Lambda Role
resource "aws_iam_role" "ip_authorizer" {
  name = "${local.project_name}-ip-authorizer-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy" "ip_authorizer" {
  name = "${local.project_name}-ip-authorizer-policy"
  role = aws_iam_role.ip_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:*:*"
      }
    ]
  })
}
