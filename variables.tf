variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "tfc_workspace" {
  type        = string
  description = "Name of the Terraform Workspace"
}

variable "tfc_organization" {
  type        = string
  description = "Name of the Terraform Organization"
}

variable "tfc_token" {
  type        = string
  description = "Token for authenticating against Terraform Cloud"
  sensitive   = true
}

variable "tfc_url" {
  type        = string
  description = "URL of the Terraform host"
  default     = "https://app.terraform.io"
}
variable "s3_versioning_is_enabled" {
  type        = bool
  description = "Enable/Disable versioning for s3"
  default     = true
}

variable "state_backup_retention_time" {
  type        = number
  description = "Retention time in days for state backup"
  default     = 30
}

variable "kms_key_alias" {
  type        = string
  description = "KMS key alias"
  default     = ""
}

variable "sns_email_addresses" {
  type        = list(string)
  description = "List of email addresses to send reports to"
  default     = []
}

variable "cw_cron_expression" {
  type        = string
  description = "Cron job to schedule the state backup"
  default     = "cron(0 23 * * ? *)"
}

variable "create_lambda_vpc_config" {
  type        = bool
  description = "Create VPC config for 'organizations', 'workspaces' and 'statebackup' lambda"
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "VPC id if creating vpc config for lambdas"
  default     = ""
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids if creating vpc vonfig for lambdas"
  default     = []

}
