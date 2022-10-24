import os
import json
import logging
from terrasnek.api import TFC
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


def handler(event, context):
    """Gets all workspaces from Terraform Cloud

        :param event: Incoming event object from AWS
        :param context: Context object from AWS
        :return: Bucket name and object key containing the workspace
    """

    print(json.dumps(event))
    logger.info(f"TFC_URL: {TFC_URL}")

    key = event["key"]
    bucket = event["bucket"]

    to_load_filename= "/tmp/org_list.json"
    
    # Download data from s3
    functions.download_file(key, to_load_filename, bucket)

    org_ids = functions.load_json(to_load_filename)

    return org_ids

