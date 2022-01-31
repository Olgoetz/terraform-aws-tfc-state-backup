output "s3_bucket" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of the S3 bucket for state backups"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.report.arn
  description = "ARN of the sns topic"
}

output "sfn_state_machine_arn" {
  value       = aws_sfn_state_machine.state_machine.arn
  description = "ARN of the sfn state machine"
}
