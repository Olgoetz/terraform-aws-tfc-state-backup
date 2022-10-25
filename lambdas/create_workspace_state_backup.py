import os
import json
import logging
import boto3
import urllib.request
from terrasnek.api import TFC, TFCHTTPNotFound
from datetime import datetime
from time import time
import ssl
from helpers import functions


# Environment variables
TFC_TOKEN = os.getenv("TFC_TOKEN", None)
TFC_URL = os.getenv("TFC_URL", "https://app.terraform.io")
S3_BUCKET = os.getenv("S3_BUCKET", None)
SSL_VERIFY = os.getenv("SSL_VERIFY", False)
TEMP_BUCKET=os.getenv("TEMP_BUCKET", None)

if SSL_VERIFY == 'false' or SSL_VERIFY is False:
    ssl_verify = False
    ssl._create_default_https_context = ssl._create_unverified_context
else:
    ssl_verify = True

# Initialize api
api = TFC(TFC_TOKEN, url=TFC_URL, verify=ssl_verify)


# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

class TFCCustomError(Exception):
    pass

def handler(event, context):
    """Gets the current state of a Terraform Cloud workspace and safes it to an s3 bucket

        :param event: Incoming event object from AWS
        :param context: Context object from AWS
        :return: Success message
    """

    print(json.dumps(event))
    logger.info(f"TFC_URL: {TFC_URL}")

    tfc_org = event["org_id"]
    ws_id = event['ws']['ws_id']
    ws_name = event['ws']['ws_name']
    logger.info(f"Workspace ID: {ws_id}")
    logger.info(f"Workspace name: {ws_name}")
    
    api.set_org(tfc_org)

    # Get the url pointing to the latest state version
    try:
    
        hosted_state_download_url = api.state_versions.get_current(
            workspace_id=ws_id)['data']['attributes']['hosted-state-download-url']
        logger.info(f"Hosted State Download Url: {hosted_state_download_url}")
    except TFCHTTPNotFound as e:
        error = {
            "org_id": tfc_org,
            "ws_name": ws_name,
            "message": "Failed to download workspace state",
            "error": e
        }
        raise TFCCustomError (error)

    # File name based on a timestamp
    path = f'{tfc_org}/{ws_name}/{datetime.now().isoformat(timespec="milliseconds").replace("-", "/").replace("T", "/state_at_")}'
    logger.info(f"Filename: {path}")

    # Download the state and safe it to the tmp folder
    logging.info("Downloading state version...")
    urllib.request.urlretrieve(
        hosted_state_download_url, f'/tmp/{ws_id}_state.json')

    # Upload to state s3
    logging.info("Uploading state version to s3...")
    file_name = f'{path}.json'
    functions.upload_file(f'/tmp/{ws_id}_state.json', S3_BUCKET, file_name)

    # Upload to temp s3
    file_name_temp = f'success/{tfc_org}_{ws_name}.json'
    logging.info(f"Uploading '{file_name_temp}' to success/ info to temp s3...")
    msg = {"message": f"Backup successfully taken for {tfc_org}/{ws_name} (S3 Path: {file_name}"}
    functions.save_json("/tmp/msg.json", msg)
    functions.upload_file("/tmp/msg.json", TEMP_BUCKET, file_name_temp)
    
    return msg


#handler({"org_id": "Oliver", "ws_id": 'ws-xGsTy18ggUmNQ2cB'}, {})
