import os
import json
import logging

from rsa import verify
import boto3
import urllib.request
from botocore.exceptions import ClientError
from terrasnek.api import TFC
from datetime import datetime
from time import time


# Environment variables
TFC_TOKEN = os.getenv("TFC_TOKEN", None)
TFC_URL = os.getenv("TFC_URL", "https://app.terraform.io")
SSL_VERIFY = os.getenv("SSL_VERIFY", False)

# Initialize api
api = TFC(TFC_TOKEN, url=TFC_URL, verify=SSL_VERIFY)


# Logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

orgs = api.orgs.list()
print(orgs["data"])


def handler(event, context):
    """Return a list of Terraform Cloud organizations

    :param event: AWS event
    :param context: AWS context
    :return: List of all Terraform Cloud organizations
    """

    result = [{"org_id": org["id"]} for org in orgs["data"]]
    logger.info(result)
    return result
