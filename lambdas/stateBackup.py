import os
import json
import logging
import boto3
import urllib.request
from botocore.exceptions import ClientError
from terrasnek.api import TFC
from datetime import datetime
from time import time
from terrasnek.exceptions import TFCHTTPNotFound
# Environment variables
TFC_TOKEN = os.getenv("TFC_TOKEN", None)
TFC_URL = os.getenv("TFC_URL", "https://app.terraform.io")
S3_BUCKET = os.getenv("S3_BUCKET", None)

# Initialize api
api = TFC(TFC_TOKEN, url=TFC_URL)


# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def upload_file(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = os.path.basename(file_name)

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logging.error(e)
        return False
    return True


def handler(event, context):
    """Gets the current state of a Terraform Cloud workspace and safes it to an s3 bucket

        :param event: Incoming event object from AWS
        :param context: Context object from AWS
        :return: Success message
    """

    print(json.dumps(event))
    logger.info(f"TFC_URL: {TFC_URL}")

    # Extract the org id
    tfc_org = event['org_id']
    logger.info(f"TFC organization: {tfc_org}")
    api.set_org(tfc_org)

    # Extract workspace id and name
    ws_id = event['ws']['ws_id']
    ws_name = event['ws']['ws_name']
    logger.info(f"Workspace ID: {ws_id}")
    logger.info(f"Workspace name: {ws_name}")

    # Get the url pointing to the latest state version
   # try:
    hosted_state_download_url = api.state_versions.get_current(
        workspace_id=ws_id)['data']['attributes']['hosted-state-download-url']
    logger.info(f"Hosted State Download Url: {hosted_state_download_url}")
   # except TFCHTTPNotFound:
   #     return ("Workspace does not have any state yet.")

    # File name based on a timestamp
    path = f'{tfc_org}/{ws_name}/{datetime.now().isoformat(timespec="milliseconds").replace("-", "/").replace("T", "/state_at_")}'
    logger.info(f"Filename: {path}")

    # Download the state and safe it to the tmp folder
    logging.info("Downloading state version...")
    urllib.request.urlretrieve(
        hosted_state_download_url, f'/tmp/{ws_id}_state.json')

    # Upload to s3
    logging.info("Uploading state version to s3...")
    file_name = f'{path}.json'
    upload_file(f'/tmp/{ws_id}_state.json', S3_BUCKET, file_name)

    return {'message': f'Backup successfully taken for {tfc_org}/{ws_name} (S3 Path: {file_name}'}


#handler({"org_id": "Oliver", "ws_id": 'ws-xGsTy18ggUmNQ2cB'}, {})
