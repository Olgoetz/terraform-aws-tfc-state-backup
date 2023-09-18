
################ STATE BACKUP S3 ################
# All states are save in this bucket
#################################################


# S3 bucket to store state versions
resource "aws_s3_bucket" "this" {
  bucket        = "${lower(local.resource_prefix)}bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.s3_force_destroy
}


# Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire"
    status = "Enabled"


    expiration {
      days = var.state_backup_retention_time
    }
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_alias != "" ? data.aws_kms_alias.this[0].target_key_id : null
    }
  }
}

# Activate versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
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


################ TEMP S3 ################
# Bucket that functions as temporary storage for step functions payloads
#################################################


# S3 bucket for payloads
resource "aws_s3_bucket" "temp" {
  bucket        = "${lower(local.resource_prefix)}temp-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.s3_force_destroy
}

# S3 ACL
resource "aws_s3_bucket_acl" "temp" {
  bucket = aws_s3_bucket.temp.id
  acl    = "private"
}


# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "temp" {
  bucket = aws_s3_bucket.temp.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_alias != "" ? data.aws_kms_alias.this[0].target_key_id : null
    }
  }
}


# Enforce private
resource "aws_s3_bucket_public_access_block" "temp" {
  bucket                  = aws_s3_bucket.temp.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow only ssl requests
resource "aws_s3_bucket_policy" "temp" {
  bucket = aws_s3_bucket.temp.bucket
  policy = jsonencode({
    Id      = "SSLOnly"
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSSLRequestsOnly",
        Action = "s3:*",
        Effect = "Deny",
        Resource = [
          aws_s3_bucket.temp.arn,
          "${aws_s3_bucket.temp.arn}/*"
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

