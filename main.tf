terraform {
  required_providers {
    aws = {
      version = "~> 3.75.0"
      source  = "hashicorp/aws"
    }
  }
}


data "aws_caller_identity" "current" {}
locals {
  resource_prefix = "TerraformStateBackup-"
}

data "aws_kms_alias" "this" {
  count = var.kms_key_alias != "" ? 1 : 0
  name  = "alias/${var.kms_key_alias}"
}
