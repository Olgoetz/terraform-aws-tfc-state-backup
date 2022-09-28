# TERRAFORM-AWS-TFC-STATE-BACKUP

The solution backups all Terraform Cloud's workspaces' states in case of an accedential deletion.

## Preqrequisites

- AWS credentials
- Terraform Cloud Token to allow to call the API

## Features

- [x] fully automated
- [x] CRON expression allows individual time for backup
- [x] State backups of all Terraform Organizations' workspaces' are taken and stored in S3
- [x] Report is sent to provided email addresses via SNS

## Example

An example can be found in `./examples`.

<!-- BEGIN_TF_DOCS --> 

<!-- END_TF_DOCS --> 
