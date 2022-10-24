resource "aws_iam_role" "replication" {
  count = var.s3_destination_arn != "" ? 1 : 0
  name  = "${local.resource_prefix}S3Replication-Role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  count = var.s3_destination_arn != "" ? 1 : 0
  name  = "${local.resource_prefix}S3Replication-Policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.this.arn}",
        "${aws_s3_bucket.this.arn}/*"
        "${var.s3_destination_arn}",
        "${var.s3_destination_arn}/*"
      ]
    },
    {
      "Action": [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.this.arn}/*",
        "${var.s3_destination_arn}/*"
      ]
    }
  ]
}
POLICY
}


resource "aws_iam_policy" "replication_with_kms" {

  count = var.s3_destination_arn != "" && (var.kms_destination_arn != "" || var.kms_key_alias != "") ? 1 : 0
  name  = "${local.resource_prefix}S3ReplicationWithKMS-Policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.s3_destination_arn != "" ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

resource "aws_iam_role_policy_attachment" "replication_with_kms" {
  count      = var.s3_destination_arn != "" && (var.kms_destination_arn != "" || var.kms_key_alias != "") ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication_with_kms[0].arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  count = var.s3_destination_arn != "" ? 1 : 0

  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.this]

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.this.id

  rule {
    id = "ReplicateAll"


    filter {
      prefix = ""
    }

    status = "Enabled"

    destination {
      bucket        = var.s3_destination_arn
      storage_class = "STANDARD"
      dynamic "encryption_configuration" {
        for_each = try([var.kms_destination_arn], [])

        content {
          replica_kms_key_id = encryption_configuration.value

        }
      }
    }

    dynamic "delete_marker_replication" {
      for_each = try([var.kms_destination_arn], [])
      content {

        status = "Enabled"
      }
    }

    dynamic "source_selection_criteria" {
      for_each = try([var.kms_destination_arn], [])

      content {

        dynamic "sse_kms_encrypted_objects" {

          for_each = try([var.kms_destination_arn], [])

          content {

            status = "Enabled"
          }
        }
      }
    }
  }
}