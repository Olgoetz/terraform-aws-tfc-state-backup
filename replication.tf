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
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.this.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.this.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${var.s3_destination_arn}/*"
    }
  ]
}
POLICY
}


resource "aws_iam_policy" "replication_with_kms" {
  count = var.s3_destination_arn != "" && var.kms_destination_arn != "" ? 1 : 0
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
      "Resource": [
        "${var.kms_destination_arn}"
      ]
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
  count      = var.s3_destination_arn != "" && var.kms_destination_arn != "" ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication_with_kms[0].arn
}