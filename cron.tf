# Cron expression
resource "aws_cloudwatch_event_rule" "state_backup" {
  name                = "${local.resource_prefix}CW-EventRule"
  description         = "Perform a state backup of all Terraform Cloud workspaces."
  schedule_expression = var.cw_cron_expression
}

# Define SFN as target
resource "aws_cloudwatch_event_target" "sfn" {
  rule      = aws_cloudwatch_event_rule.state_backup.name
  target_id = "TriggerSFN"
  arn       = aws_sfn_state_machine.state_machine.arn
  role_arn  = aws_iam_role.cw_role.arn
}


# IAM
# ---------------------------------------------------


# Role

resource "aws_iam_role" "cw_role" {
  name = "${local.resource_prefix}CWEvent-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["sts:AssumeRole"]
      Effect = "Allow"
      Principal = {

        Service = ["states.amazonaws.com", "events.amazonaws.com"]
      }
      },
    ]

    }
  )
}

# Policy definition
data "aws_iam_policy_document" "cw_role_policy" {
  statement {
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.state_machine.arn]
  }
}

# Policy resource
resource "aws_iam_role_policy" "cw_role_policy" {
  name   = "${local.resource_prefix}CWEvent-Policy"
  policy = data.aws_iam_policy_document.cw_role_policy.json
  role   = aws_iam_role.cw_role.id
}
