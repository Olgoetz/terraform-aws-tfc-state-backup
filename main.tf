terraform {
  required_providers {
    aws = {
      version = ">= 3.72.0"
      source  = "hashicorp/aws"
    }
  }
}
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}

data "aws_kms_alias" "this" {
  count = var.kms_key_alias != "" ? 1 : 0
  name  = "alias/${var.kms_key_alias}"
}

locals {
  resource_prefix = "TerraformStateBackup-"
}
