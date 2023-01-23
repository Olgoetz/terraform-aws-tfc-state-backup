from cmath import log
import boto3
import os
import logging
import json
sns_client = boto3.client("sns")
s3_client = boto3.client("s3")


SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")
TEMP_BUCKET=os.getenv("TEMP_BUCKET", None)

# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)



def handler(event, context):
    """Send a report about failed and successfull state backups

    :param event: AWS event
    :param context: AWS context
    :return: Success message
    """

    #print(json.dumps(event))
    
    ## SUCCESSFUL BACKUPS
    
    successful = []
    # Init call
    successful_init_response = s3_client.list_objects_v2(
        Bucket=TEMP_BUCKET,
        Prefix='success'
    )

    logger.info("Init response for successful state backups:")
    logger.info(successful_init_response)

    successful = successful + successful_init_response['Contents']

    continuation_token = successful_init_response.get('NextContinuationToken')

    # Loop through the pages
    while continuation_token:
        response = s3_client.list_objects_v2(
            Bucket=TEMP_BUCKET,
            Prefix='success',
            ContinuationToken = continuation_token
        )
        continuation_token = response.get('NextContinuationToken')
        successful = successful + response['Contents']

    
    ## FAILED BACKUPS
    
    failed = []

    # Init call
    failed_init_response = s3_client.list_objects_v2(
        Bucket=TEMP_BUCKET,
        Prefix='failed'
    )

    logger.info("Init response for failed state backups:")
    logger.info(failed_init_response)
    
    failed = failed + failed_init_response['Contents']

    continuation_token = failed_init_response.get('NextContinuationToken')

    # Loop through the pages
    while continuation_token:
        response = s3_client.list_objects_v2(
            Bucket=TEMP_BUCKET,
            Prefix='success',
            ContinuationToken=continuation_token
        )
        continuation_token = response.get('NextContinuationToken')
        failed = failed + response['Contents']

    ## MESSAGE
    message = f"""
    
{len(successful)} state backups were successful.
        
----------------------------------------------------------------------------------------
    
{len(failed)} state backups failed:  More information can be found in the logs.
    
For instance you can fire the following command in cloudwatch insights for /aws/lambda/TerraformStateBackup-create_workspace_state_backup:

    fields @timestamp, @message
    | sort @timestamp desc
    | filter @message like "[ERROR]"
    | limit 20
        
        
"""
    response = sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='TerraformCloud-StateBackup-Report',
        Message=message,
    )
    logger.info(response)

    return "Report sent!"
