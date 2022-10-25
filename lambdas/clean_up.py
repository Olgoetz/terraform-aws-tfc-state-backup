from cmath import log
import boto3
import botocore
import os
import logging
import json
s3_resource = boto3.resource("s3")


TEMP_BUCKET=os.getenv("TEMP_BUCKET", None)

# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)



def handler(event, context):
    """Empties the temp bucket.

    :param event: AWS event
    :param context: AWS context
    :return: Success message
    """

    print(json.dumps(event))

    bucket = s3_resource.Bucket(TEMP_BUCKET)

    logger.info("Emptying the bucket...")
    try:
        bucket.objects.delete()
    except botocore.exceptions.ClientError as error:
        logger.error(error)
        raise error
    return "Temp bucket deleted!"
