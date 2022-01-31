import boto3
import os
import logging
import json
sns_client = boto3.client("sns")


SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """Send a report about failed and successfull state backaups

    :param event: AWS event
    :param context: AWS context
    :return: Success message
    """

    _failed = event['failed']

    failed = [{"org_id": el['org_id'], "ws": el['ws'], "Error": {
        "errorType": el['Error']['errorType'], 'errorMessage': el['Error']['errorMessage']}} for el in _failed]

    successful = event['successful']
    message = f"""
    
The following state backups were successful:
    
{json.dumps(successful, indent=4, sort_keys=False)}
        
----------------------------------------------------------------------------------------
    
The following state backups failed:
    
{json.dumps(failed, indent=4, sort_keys=False)}
        
        
"""
    response = sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='TerraformCloud-StateBackup-Report',
        Message=message,
    )
    logger.info(response)

    return "Report sent!"
