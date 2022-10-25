import os
import json
import logging


import boto3
import urllib.request
from botocore.exceptions import ClientError
from terrasnek.api import TFC, TFCHTTPNotFound
from datetime import datetime
from time import time
from helpers import functions


# Environment variables
TFC_TOKEN = os.getenv("TFC_TOKEN", None)
TFC_URL = os.getenv("TFC_URL", "https://app.terraform.io")
SSL_VERIFY = os.getenv("SSL_VERIFY", False)
TEMP_BUCKET=os.getenv("TEMP_BUCKET", None)

if SSL_VERIFY == 'false' or SSL_VERIFY is False:
    ssl_verify = False
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
    """Return a list of Terraform Cloud organizations

    :param event: AWS event
    :param context: AWS context
    :return: List of all Terraform Cloud organizations
    """

    logger.info("Getting all orgas...")
    try:
        orgs = api.orgs.list()

    except TFCHTTPNotFound as e:
        error = {
            "message": "Failed to query all orgas from TFC",
            "error": e
        }
        raise TFCCustomError (error)

    result = [{"org_id": org["id"]} for org in orgs["data"]]
    logger.info(result)
    
    file_name = "/tmp/org_list.json"
    object_name = "orgas/org_list.json"
    functions.save_json(file_name, result)
    functions.upload_file(file_name, TEMP_BUCKET, object_name)

    return {
        "key": object_name,
        "bucket": f"arn:aws:s3:::{TEMP_BUCKET}"
        }
