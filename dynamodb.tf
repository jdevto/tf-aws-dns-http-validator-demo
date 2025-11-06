# DynamoDB table for storing validation results

resource "aws_dynamodb_table" "validations" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "requestId"
  range_key    = "step"

  attribute {
    name = "requestId"
    type = "S"
  }

  attribute {
    name = "step"
    type = "S"
  }

  attribute {
    name = "target"
    type = "S"
  }

  attribute {
    name = "time"
    type = "S"
  }

  # GSI: byTarget
  global_secondary_index {
    name            = "byTarget"
    hash_key        = "target"
    range_key       = "time"
    projection_type = "ALL"
  }

  tags = local.tags
}
