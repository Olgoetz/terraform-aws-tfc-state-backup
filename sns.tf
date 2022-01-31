resource "aws_sns_topic" "report" {
  name              = "${local.resource_prefix}SNS-ReportTopic"
  kms_master_key_id = var.kms_key_alias ? data.kms_key_alias.this[0].name : "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "email" {
  for_each  = toset(var.sns_email_addresses)
  topic_arn = aws_sns_topic.report.arn
  protocol  = "email"
  endpoint  = each.value
}
