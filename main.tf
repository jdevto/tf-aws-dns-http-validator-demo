# Get current user's public IP
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com/"
}

# Get current region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}
