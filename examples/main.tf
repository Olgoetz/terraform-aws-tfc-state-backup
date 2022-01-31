variable "tfc_token" {
  type        = string
  description = "Token for authenticating against Terraform Cloud"
  sensitive   = true
}



provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {}
  }
}




module "statebackup" {
  source              = "../"
  tfc_token           = var.tfc_token
  sns_email_addresses = ["address@email.com"]
  s3_force_destroy    = true
}


