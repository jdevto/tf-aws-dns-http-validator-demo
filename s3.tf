# S3 bucket for static website hosting

resource "aws_s3_bucket" "frontend" {
  bucket = "${local.project_name}-frontend-${data.aws_caller_identity.current.account_id}"

  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  # Allow public access for website hosting
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public read access
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Frontend deployment
resource "aws_s3_object" "frontend_files" {
  for_each = fileset("${path.module}/frontend/dist", "**")

  depends_on = [null_resource.frontend_build]

  bucket = aws_s3_bucket.frontend.id
  key    = each.value
  source = "${path.module}/frontend/dist/${each.value}"
  etag   = filemd5("${path.module}/frontend/dist/${each.value}")

  lifecycle {
    replace_triggered_by = [null_resource.frontend_build]
  }

  # Determine content type based on file extension
  content_type = try(
    {
      "html"  = "text/html"
      "css"   = "text/css"
      "js"    = "application/javascript"
      "json"  = "application/json"
      "png"   = "image/png"
      "jpg"   = "image/jpeg"
      "jpeg"  = "image/jpeg"
      "svg"   = "image/svg+xml"
      "ico"   = "image/x-icon"
      "woff"  = "font/woff"
      "woff2" = "font/woff2"
    }[split(".", each.value)[length(split(".", each.value)) - 1]],
    "application/octet-stream"
  )
}
