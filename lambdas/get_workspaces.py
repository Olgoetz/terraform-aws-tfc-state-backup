import os
import json
import logging
from lambdas.get_organizations import TEMP_BUCKET
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
    # Configure api
    tfc_org = event["org_id"]
    api.set_org(tfc_org)

    # Get workspace ids
    workspaces = api.workspaces.list_all()["data"]
    workspace_ids = [
        {"ws_id": ws["id"], "ws_name": ws["attributes"]["name"]} for ws in workspaces]

    logger.info(workspace_ids)
    file_name = f'/tmp/{tfc_org}/workspace_ids.json'
    object_name = f'/workspaces/{tfc_org}.json'
    functions.save_json(file_name, workspace_ids)
    functions.upload_file(file_name, TEMP_BUCKET, object_name)

    return {
        "key": object_name,
        "bucket": f"arn:aws:s3:::{TEMP_BUCKET}"
        }
