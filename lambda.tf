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
  count = length(var.subnet_ids) != 0 ? 1 : 0
  id    = var.vpc_id
}

resource "aws_security_group" "lambda" {
  count       = length(var.subnet_ids) != 0 ? 1 : 0
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


# sources/get_organizations.py

data "archive_file" "get_organizations" {
  type        = "zip"
  source_file = "${path.module}/lambdas/get_organizations.py"
  output_path = "${path.module}/get_organizations.zip"
}

resource "aws_lambda_function" "get_organizations" {
  filename         = data.archive_file.get_organizations.output_path
  function_name    = "${local.resource_prefix}get-organizations"
  role             = aws_iam_role.this.arn
  handler          = "get_organizations.handler"
  description      = "Returns all Terraform Cloud organizations and saves them in an s3 bucket."
  source_code_hash = data.archive_file.get_organizations.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) != 0 ? [1] : []

    content {

      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }
  environment {
    variables = {
      TFC_URL     = var.tfc_url
      TFC_TOKEN   = var.tfc_token
      SSL_VERIFY  = var.tfc_ssl_verify
      TEMP_BUCKET = aws_s3_bucket.temp.bucket
    }
  }
}


# sources/prepare_organizations.py

data "archive_file" "prepare_organizations" {
  type        = "zip"
  source_file = "${path.module}/lambdas/prepare_organizations.py"
  output_path = "${path.module}/prepare_organizations.zip"
}

resource "aws_lambda_function" "prepare_organizations" {
  filename         = data.archive_file.prepare_organizations.output_path
  function_name    = "${local.resource_prefix}prepare-organizations"
  role             = aws_iam_role.this.arn
  handler          = "prepare_organizations.handler"
  description      = "Provides a list org ids."
  source_code_hash = data.archive_file.prepare_organizations.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  # dynamic "vpc_config" {
  #   for_each = length(var.subnet_ids) != 0 ? [1] : []

  #   content {

  #     subnet_ids         = var.subnet_ids
  #     security_group_ids = [aws_security_group.lambda[0].id]
  #   }
  # }
  environment {
    variables = {
      TFC_URL     = var.tfc_url
      TFC_TOKEN   = var.tfc_token
      SSL_VERIFY  = var.tfc_ssl_verify
      TEMP_BUCKET = aws_s3_bucket.temp.bucket
    }
  }
}

# sources/get_workspaces.py

data "archive_file" "get_workspaces" {
  type        = "zip"
  source_file = "${path.module}/lambdas/get_workspaces.py"
  output_path = "${path.module}/get_workspaces.zip"

}

resource "aws_lambda_function" "get_workspaces" {
  filename         = data.archive_file.get_workspaces.output_path
  function_name    = "${local.resource_prefix}get-workspaces"
  role             = aws_iam_role.this.arn
  handler          = "get_workspaces.handler"
  description      = "Returns all workspaces of a Terraform Cloud organization and saves them to s3."
  source_code_hash = data.archive_file.get_workspaces.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) != 0 ? [1] : []

    content {

      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }

  environment {
    variables = {
      TFC_URL     = var.tfc_url
      TFC_TOKEN   = var.tfc_token
      SSL_VERIFY  = var.tfc_ssl_verify
      TEMP_BUCKET = aws_s3_bucket.temp.bucket
    }
  }
}

# sources/prepare_workspaces.py

data "archive_file" "prepare_workspaces" {
  type        = "zip"
  source_file = "${path.module}/lambdas/prepare_workspaces.py"
  output_path = "${path.module}/prepare_workspaces.zip"

}

resource "aws_lambda_function" "prepare_workspaces" {
  filename         = data.archive_file.prepare_workspaces.output_path
  function_name    = "${local.resource_prefix}prepare-workspaces"
  role             = aws_iam_role.this.arn
  handler          = "prepare_workspaces.handler"
  description      = "Prepares a list of workspaces for a specific orga."
  source_code_hash = data.archive_file.prepare_workspaces.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  # dynamic "vpc_config" {
  #   for_each = length(var.subnet_ids) != 0 ? [1] : []

  #   content {

  #     subnet_ids         = var.subnet_ids
  #     security_group_ids = [aws_security_group.lambda[0].id]
  #   }
  # }

  environment {
    variables = {
      TFC_URL     = var.tfc_url
      TFC_TOKEN   = var.tfc_token
      SSL_VERIFY  = var.tfc_ssl_verify
      TEMP_BUCKET = aws_s3_bucket.temp.bucket
    }
  }
}

# sources/create_workspace_state_backup.py

data "archive_file" "create_workspace_state_backup" {
  type        = "zip"
  source_file = "${path.module}/lambdas/create_workspace_state_backup.py"
  output_path = "${path.module}/create_workspace_state_backup.zip"

}

resource "aws_lambda_function" "create_workspace_state_backup" {
  filename         = data.archive_file.create_workspace_state_backup.output_path
  function_name    = "${local.resource_prefix}create_workspace_state_backup"
  role             = aws_iam_role.this.arn
  handler          = "create_workspace_state_backup.handler"
  description      = "Uploads the current state version of a Terraform workspace to s3."
  source_code_hash = data.archive_file.create_workspace_state_backup.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) != 0 ? [1] : []

    content {

      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }
  environment {
    variables = {
      TFC_URL     = var.tfc_url
      TFC_TOKEN   = var.tfc_token
      S3_BUCKET   = aws_s3_bucket.this.bucket
      SSL_VERIFY  = var.tfc_ssl_verify
      TEMP_BUCKET = aws_s3_bucket.temp.bucket
    }
  }
}


# sources/send_report.py

data "archive_file" "send_report" {
  type        = "zip"
  source_file = "${path.module}/lambdas/send_report.py"
  output_path = "${path.module}/send_report.zip"

}

resource "aws_lambda_function" "send_report" {
  filename         = data.archive_file.send_report.output_path
  function_name    = "${local.resource_prefix}send_report"
  role             = aws_iam_role.this.arn
  handler          = "send_report.handler"
  description      = "Sends a notification to the provided SNS topic."
  source_code_hash = data.archive_file.send_report.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.report.arn
      TEMP_BUCKET   = aws_s3_bucket.temp.bucket
    }
  }
}

# sources/handle_error.py

data "archive_file" "handle_error" {
  type        = "zip"
  source_file = "${path.module}/lambdas/handle_error.py"
  output_path = "${path.module}/handle_error.zip"

}

resource "aws_lambda_function" "handle_error" {
  filename         = data.archive_file.handle_error.output_path
  function_name    = "${local.resource_prefix}handle_error"
  role             = aws_iam_role.this.arn
  handler          = "handle_error.handler"
  description      = "Sends a notification to the provided SNS topic."
  source_code_hash = data.archive_file.handle_error.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.report.arn
      TEMP_BUCKET   = aws_s3_bucket.temp.bucket
    }
  }
}

# sources/clean_up.py

data "archive_file" "clean_up" {
  type        = "zip"
  source_file = "${path.module}/lambdas/clean_up.py"
  output_path = "${path.module}/clean_up.zip"

}

resource "aws_lambda_function" "clean_up" {
  filename         = data.archive_file.clean_up.output_path
  function_name    = "${local.resource_prefix}clean_up"
  role             = aws_iam_role.this.arn
  handler          = "clean_up.handler"
  description      = "Emtpies the temp bucket."
  source_code_hash = data.archive_file.clean_up.output_base64sha256
  timeout          = "20"
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda_layer.arn]

  environment {
    variables = {
      TEMP_BUCKET = aws_s3_bucket.temp.bucket
    }
  }
}


# CloudWatch
# ---------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([
    aws_lambda_function.get_organizations.function_name,
    aws_lambda_function.prepare_organizations.function_name,
    aws_lambda_function.get_workspaces.function_name,
    aws_lambda_function.prepare_workspaces.function_name,
    aws_lambda_function.create_workspace_state_backup.function_name,
    aws_lambda_function.send_report.function_name,
    aws_lambda_function.handle_error.function_name,
    aws_lambda_function.clean_up.function_name
  ])
  name              = "/aws/lambda/${each.value}"
  retention_in_days = 14
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
    sid     = "S3"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:List*", "s3:GetObject*", "s3:DeleteObject*"]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
      aws_s3_bucket.temp.arn,
      "${aws_s3_bucket.temp.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "s3" {
  name   = "${local.resource_prefix}Lambda-S3-Policy"
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3.arn
}

# EC2 policy
resource "aws_iam_role_policy_attachment" "ec2" {
  count      = length(var.subnet_ids) != 0 ? 1 : 0
  role       = aws_iam_role.this.name
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
  name   = "${local.resource_prefix}Lambda-KMS-Policy"
  policy = data.aws_iam_policy_document.kms[0].json
}

resource "aws_iam_role_policy_attachment" "kms" {
  count      = var.kms_key_alias != "" ? 1 : 0
  role       = aws_iam_role.this.name
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

resource "aws_iam_role_policy_attachment" "sns" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.sns.arn
}


# CloudWatch
resource "aws_iam_role_policy_attachment" "cw" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
