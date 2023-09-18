variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "default_tags" {
  type        = map(any)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "prefix" {
  type        = string
  default     = "TFC-StateBackup"
  description = "Prefix for all resources"
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

variable "tfc_ssl_verify" {
  type        = bool
  description = "Enable HTTPS"
  default     = true
}
variable "s3_versioning_is_enabled" {
  type        = bool
  description = "Enable/Disable versioning for s3"
  default     = true
}

variable "s3_force_destroy" {
  type        = bool
  description = "Force destruction of S3 bucket by emptying it"
  default     = false
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

variable "s3_destination_arn" {
  type        = string
  default     = ""
  description = "S3 destination arn for object replication"
}

variable "kms_destination_arn" {
  type        = string
  default     = ""
  description = "KMS key arn in for repilcation s3 destination"
}

