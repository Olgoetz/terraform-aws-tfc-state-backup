from cmath import log
import boto3
import os
import logging
import json
sns_client = boto3.client("sns")


SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")

# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def flatten(t):
    return [item for sublist in t for item in sublist]


def handler(event, context):
    """Send a report about failed and successfull state backaups

    :param event: AWS event
    :param context: AWS context
    :return: Success message
    """

    flattened = flatten(event)

    # Succesful backups
    successful = [el for el in flattened if 'Error' not in el]
    logger.info("Successful backups:")
    logger.info(successful)

    # Failed backups
    failed = [el for el in flattened if 'Error' in el]
    logger.info("Failed backups:")
    logger.info(failed)

    message = f"""
    
{len(successful)} state backups were successful. More information can be found in the logs
        
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
