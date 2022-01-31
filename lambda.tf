# Lambda layer containing 'terrasnek'
# ---------------------------------------------------

data "archive_file" "lambda_layer" {
  type        = "zip"
  source_dir  = "${path.module}/sources"
  output_path = "${path.module}/python_packages.zip"
}
resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = data.archive_file.lambda_layer.output_path
  layer_name = "${local.resource_prefix}Lambda-Layer"

  compatible_runtimes = ["python3.9"]
}


# Security group
# ---------------------------------------------------

data "aws_vpc" "this" {
  count = var.create_lambda_vpc_config ? 1 : 0
  id    = var.vpc_id
}

resource "aws_security_group" "lambda" {
  count       = var.create_lambda_vpc_config ? 1 : 0
  name        = "${local.resource_prefix}SG-Lambda"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.this[0].id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this[0].cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Functions
# ---------------------------------------------------


# sources/organizations.py

data "archive_file" "organizations" {
  type        = "zip"
  source_file = "${path.module}/lambdas/organizations.py"
  output_path = "${path.module}/organizations.zip"
}

resource "aws_lambda_function" "organizations" {
  filename         = data.archive_file.organizations.output_path
  function_name    = "${local.resource_prefix}organizations-Lambda-Function"
  role             = aws_iam_role.this.arn
  handler          = "organizations.handler"
  description      = "Returns all Terraform Cloud organizations."
  source_code_hash = data.archive_file.organizations.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  dynamic "vpc_config" {
    for_each = var.create_lambda_vpc_config ? [1] : []

    content {

      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }
  environment {
    variables = {
      TFC_URL   = var.tfc_url
      TFC_TOKEN = var.tfc_token
    }
  }
}

# sources/organizations.py

data "archive_file" "workspaces" {
  type        = "zip"
  source_file = "${path.module}/lambdas/workspaces.py"
  output_path = "${path.module}/workspaces.zip"

}

resource "aws_lambda_function" "workspaces" {
  filename         = data.archive_file.workspaces.output_path
  function_name    = "${local.resource_prefix}workspaces-Lambda-Function"
  role             = aws_iam_role.this.arn
  handler          = "workspaces.handler"
  description      = "Returns all workspaces of a Terraform Cloud organization."
  source_code_hash = data.archive_file.workspaces.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  dynamic "vpc_config" {
    for_each = var.create_lambda_vpc_config ? [1] : []

    content {

      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }

  environment {
    variables = {
      TFC_URL   = var.tfc_url
      TFC_TOKEN = var.tfc_token
    }
  }
}

# sources/stateBackup.py

data "archive_file" "statebackup" {
  type        = "zip"
  source_file = "${path.module}/lambdas/stateBackup.py"
  output_path = "${path.module}/stateBackup.zip"

}

resource "aws_lambda_function" "statebackup" {
  filename         = data.archive_file.statebackup.output_path
  function_name    = "${local.resource_prefix}statebackup-Lambda-Function"
  role             = aws_iam_role.this.arn
  handler          = "stateBackup.handler"
  description      = "Uploads the current state version of a Terraform workspace to s3."
  source_code_hash = data.archive_file.statebackup.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  dynamic "vpc_config" {
    for_each = var.create_lambda_vpc_config ? [1] : []

    content {

      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }
  environment {
    variables = {
      TFC_URL   = var.tfc_url
      TFC_TOKEN = var.tfc_token
      S3_BUCKET = aws_s3_bucket.this.bucket
    }
  }
}


# sources/sendReport.py

data "archive_file" "sendreport" {
  type        = "zip"
  source_file = "${path.module}/lambdas/sendReport.py"
  output_path = "${path.module}/sendReport.zip"

}

resource "aws_lambda_function" "sendreport" {
  filename         = data.archive_file.sendreport.output_path
  function_name    = "${local.resource_prefix}sendreport-Lambda-Function"
  role             = aws_iam_role.this.arn
  handler          = "sendReport.handler"
  description      = "Sends a notification to the provided SNS topic."
  source_code_hash = data.archive_file.sendreport.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.report.arn
    }
  }
}

# CloudWatch
# ---------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([aws_lambda_function.organizations.function_name,
    aws_lambda_function.workspaces.function_name,
    aws_lambda_function.statebackup.function_name,
  aws_lambda_function.sendreport.function_name])
  name              = "/aws/lambda/${each.value}"
  retention_in_days = 30
}

# IAM
# ---------------------------------------------------

resource "aws_iam_role" "this" {
  name = "${local.resource_prefix}Lambda-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# S3 Policy
data "aws_iam_policy_document" "s3" {
  statement {
    sid       = "UploadToS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
  }
}

resource "aws_iam_policy" "s3" {
  name   = "${local.resource_prefix}Lambda-S3-Policy"
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_policy_attachment" "s3" {
  name       = "${aws_iam_role.this.name}-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = aws_iam_policy.s3.arn
}

# EC2 policy
resource "aws_iam_policy_attachment" "ec2" {
  count      = var.create_lambda_vpc_config ? 1 : 0
  name       = "${aws_iam_role.this.name}-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


# KMS policy
data "aws_iam_policy_document" "kms" {
  count = var.kms_key_alias != "" ? 1 : 0
  statement {
    effect    = "Allow"
    sid       = "AllowUsageOfKMSKey"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
    resources = [data.aws_kms_alias.this[0].target_key_arn]
  }
}

resource "aws_iam_policy" "kms" {
  count  = var.kms_key_alias != "" ? 1 : 0
  name   = "${local.resource_prefix}Lambda-S3-Policy"
  policy = data.aws_iam_policy_document.kms[0].json
}

resource "aws_iam_policy_attachment" "kms" {
  count      = var.kms_key_alias != "" ? 1 : 0
  name       = "${aws_iam_role.this.name}-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = aws_iam_policy.kms[0].arn
}

# SNS Policy
data "aws_iam_policy_document" "sns" {
  statement {
    sid       = "PublishSNS"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.report.arn]
  }
}

resource "aws_iam_policy" "sns" {
  name   = "${local.resource_prefix}Lambda-SNS-Policy"
  policy = data.aws_iam_policy_document.sns.json
}

resource "aws_iam_policy_attachment" "sns" {
  name       = "${aws_iam_role.this.name}-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = aws_iam_policy.sns.arn
}


# CloudWatch
resource "aws_iam_policy_attachment" "cw" {
  name       = "${aws_iam_role.this.name}-attachment"
  roles      = [aws_iam_role.this.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
