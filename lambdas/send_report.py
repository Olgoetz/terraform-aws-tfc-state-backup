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

    print(json.dumps(event))
    
    ## SUCCESSFUL BACKUPS
    successful = []
    # Init call
    successful_init_response = s3_client.list_objects_v2(
        Bucket=TEMP_BUCKET,
        Delimiter='success'
    )
    successful = successful + successful_init_response['Contents']

    # Loop through the pages
    successful_next_continuation_token = successful_init_response['NextContinuationToken']
    while successful_next_continuation_token:
        response = s3_client.list_objects_v2(
            Bucket=TEMP_BUCKET,
            Delimiter='success',
            ContinuationToken = successful_next_continuation_token
        )
        successful_next_continuation_token = response['NextContinuationToken']
        successful = successful + response['Contents']

    
    ## FAILED BACKUPS
    failed = []
    # Init call
    failed_init_response = s3_client.list_objects_v2(
        Bucket=TEMP_BUCKET,
        Delimiter='error'
    )
    failed = failed + failed_init_response['Contents']

    # Loop through the pages
    failed_next_continuation_token = failed_init_response['NextContinuationToken']
    while failed_next_continuation_token:
        response = s3_client.list_objects_v2(
            Bucket=TEMP_BUCKET,
            Delimiter='error',
            ContinuationToken = failed_next_continuation_token
        )
        failed_next_continuation_token = response['NextContinuationToken']
        failed = failed + response['Contents']


    ## MESSAGE
    message = f"""
    
{len(successful)} state backups were successful. More information can be found in the logs.
        
----------------------------------------------------------------------------------------
    
{len(failed)} state backups failed:
    
{json.dumps(failed, indent=4, sort_keys=False)}
        
        
"""
    response = sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='TerraformCloud-StateBackup-Report',
        Message=message,
    )
    logger.info(response)

    return "Report sent!"
