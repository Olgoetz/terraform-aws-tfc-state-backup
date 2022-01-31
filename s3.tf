# S3 bucket to store state versions
resource "aws_s3_bucket" "this" {

  bucket = "${lower(local.resource_prefix)}${lower(var.tfc_organization)}-${lower(var.tfc_workspace)}-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  lifecycle_rule {
    id      = "expire"
    enabled = true


    expiration {
      days = var.state_backup_retention_time
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = var.kms_key_alias != "" ? data.aws_kms_alias.this[0].target_key_id : null
      }
    }
  }

  versioning {
    enabled = var.s3_versioning_is_enabled
  }

}

# Enforce private
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow only ssl requests
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.bucket
  policy = jsonencode({
    Id      = "SSLOnly"
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSSLRequestsOnly",
        Action = "s3:*",
        Effect = "Deny",
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
        Principal = "*"
      }
    ]
    }
  )
}
