# EventBridge custom bus

resource "aws_cloudwatch_event_bus" "dns_checks" {
  name = local.eventbus_name

  tags = local.tags
}

# Rule: ValidationRequested → triggers dns-resolver
resource "aws_cloudwatch_event_rule" "validation_requested" {
  name           = "${local.project_name}-rule-validation-requested"
  event_bus_name = aws_cloudwatch_event_bus.dns_checks.name
  description    = "Trigger DNS resolver on ValidationRequested events"

  event_pattern = jsonencode({
    detail-type = ["ValidationRequested"]
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "validation_requested" {
  rule           = aws_cloudwatch_event_rule.validation_requested.name
  event_bus_name = aws_cloudwatch_event_bus.dns_checks.name
  arn            = aws_lambda_function.dns_resolver.arn
}

# Rule: DNSResolved → triggers http-prober and https-prober
resource "aws_cloudwatch_event_rule" "dns_resolved" {
  name           = "${local.project_name}-rule-dns-resolved"
  event_bus_name = aws_cloudwatch_event_bus.dns_checks.name
  description    = "Trigger HTTP and HTTPS probers on DNSResolved events"

  event_pattern = jsonencode({
    detail-type = ["DNSResolved"]
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "dns_resolved_http" {
  rule           = aws_cloudwatch_event_rule.dns_resolved.name
  event_bus_name = aws_cloudwatch_event_bus.dns_checks.name
  arn            = aws_lambda_function.http_prober.arn
}

resource "aws_cloudwatch_event_target" "dns_resolved_https" {
  rule           = aws_cloudwatch_event_rule.dns_resolved.name
  event_bus_name = aws_cloudwatch_event_bus.dns_checks.name
  arn            = aws_lambda_function.https_prober.arn
}

# Rule: All result events → triggers aggregator
resource "aws_cloudwatch_event_rule" "aggregator_events" {
  name           = "${local.project_name}-rule-aggregator"
  event_bus_name = aws_cloudwatch_event_bus.dns_checks.name
  description    = "Trigger aggregator on DNS and HTTP result events"

  event_pattern = jsonencode({
    detail-type = ["DNSResolved", "DNSFailed", "HTTPChecked", "HTTPSChecked"]
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "aggregator" {
  rule           = aws_cloudwatch_event_rule.aggregator_events.name
  event_bus_name = aws_cloudwatch_event_bus.dns_checks.name
  arn            = aws_lambda_function.aggregator.arn
}
