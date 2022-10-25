
# STATE MACHINE DEFINITON
# --------------------------------------------------------------------------------

resource "aws_sfn_state_machine" "state_machine" {
  name     = "${local.resource_prefix}SFN-StateMachine"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = templatefile("${path.module}/state_machine.json", {
    get_organizations_lambda             = aws_lambda_function.get_organizations.arn,
    prepare_organizations_lambda         = aws_lambda_function.prepare_organizations.arn,
    get_workspaces_lambda                = aws_lambda_function.get_workspaces.arn,
    prepare_workspaces_lambda            = aws_lambda_function.prepare_workspaces.arn,
    create_workspace_state_backup_lambda = aws_lambda_function.create_workspace_state_backup.arn,
    send_report_lambda                   = aws_lambda_function.send_report.arn,
    handle_error_lambda                  = aws_lambda_function.handle_error.arn,
    clean_up_lambda                      = aws_lambda_function.clean_up.arn
  })
}


# IAM
# --------------------------------------------------------------------------------

# Role
resource "aws_iam_role" "step_functions_role" {
  name               = "${local.resource_prefix}SFN-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Policy document
data "aws_iam_policy_document" "step_functions_policy" {
  statement {

    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.get_organizations.arn,
      aws_lambda_function.prepare_organizations.arn,
      aws_lambda_function.get_workspaces.arn,
      aws_lambda_function.prepare_workspaces.arn,
      aws_lambda_function.create_workspace_state_backup.arn,
      aws_lambda_function.send_report.arn,
      aws_lambda_function.handle_error.arn,
      aws_lambda_function.clean_up.arn
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.report.arn]
  }


}

# Policy
resource "aws_iam_policy" "step_function_policy" {
  name   = "${local.resource_prefix}SFN-Policy"
  policy = data.aws_iam_policy_document.step_functions_policy.json

}

# Polic attachment
resource "aws_iam_role_policy_attachment" "step_functions_role_attachment" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}
