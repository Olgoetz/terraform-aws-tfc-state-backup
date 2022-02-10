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


def return_not_found_message(errors):
    """Returns a f-string if an endpoint is not found.

    :param errors: List of object containing errors
    :return: message
    """
    not_found_error = [{"org_id": el['org_id'], "ws": el['ws']} for el in errors if
                       el['Error']['errorType'] == "TFCHTTPNotFound"]
    if len(not_found_error) > 0:
        return f"""
        - {len(not_found_error)} failed because the workspaces do not have any state yet.
        """


def return_other_error_message(errors):
    """Returns a f-string if any other errors than 'TFCHTTPNOTFOUND' occurs.

     :param errors: List of object containing errors
     :return: message
     """

    other_error = [{"org_id": el['org_id'], "ws": el['ws'], "error": el['errorMessage']} for el in errors if
                   el['Error']['errorType'] != "TFCHTTPNotFound"]
    if len(other_error) > 0:
        return f"""
        - {len(other_error)} failed because of a different reason:

            {json.dumps(other_error, indent=4, sort_keys=False)}     
        """
    else:
        return f"""
        - {len(other_error)} other failures.
        """


def handler(event, context):
    """Send a report about failed and successful state backups

    :param event: AWS event
    :param context: AWS context
    :return: Success message
    """

    flattened = flatten(event)

    # Successful backups
    successful = [el for el in flattened if 'Error' not in el]
    logger.info("Successful backups:")
    logger.info(successful)

    # Failed backups
    failed = [el for el in flattened if 'Error' in el]
    logger.info("Failed backups:")
    logger.info(failed)



    message = f"""
    
{len(successful)} state backups were successful. More information can be found in the logs.
        
----------------------------------------------------------------------------------------
    
{len(failed)} state backups failed:
    
{return_not_found_message(failed)}
{return_other_error_message(failed)}
        
        
"""
    response = sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='TerraformCloud-StateBackup-Report',
        Message=message,
    )
    logger.info(response)

    return "Report sent!"

