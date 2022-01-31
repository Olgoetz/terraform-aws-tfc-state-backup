import os
import json
import logging
from terrasnek.api import TFC

# Environment variables
TFC_TOKEN = os.getenv("TFC_TOKEN", None)
TFC_URL = os.getenv("TFC_URL", "https://app.terraform.io")


# Initialize api
api = TFC(TFC_TOKEN, url=TFC_URL)


# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """Gets the current state of a Terraform Cloud workspace and safes it to an s3 bucket

        :param event: Incoming event object from AWS
        :param context: Context object from AWS
        :return: Success message
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

    return workspace_ids
