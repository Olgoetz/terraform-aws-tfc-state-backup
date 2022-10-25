from cmath import log
import os
import logging
import json

from helpers import functions



TEMP_BUCKET=os.getenv("TEMP_BUCKET", None)

# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)



def handler(event, context):
    """Handle errored backups

    :param event: AWS event
    :param context: AWS context
    :return: True
    """

    print(json.dumps(event))

    tfc_org = event["org_id"]
    ws_name = event['ws']['ws_name']

    file_name = f'/tmp/{tfc_org}_{ws_name}.json'
    object_name = f'failed/{tfc_org}_{ws_name}.json'
    functions.save_json(file_name, event)

    logger.info("Uploading error to temp s3 bucket...")
    functions.upload_file(file_name, TEMP_BUCKET, object_name)

    
    msg = {
        "org_id": tfc_org,
        "ws_name": ws_name,
        "message": "Failed to download workspace state."
    }
    return msg