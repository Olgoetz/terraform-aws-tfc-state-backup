import os
import json
import logging
from helpers import functions

# Environment variables
SSL_VERIFY = os.getenv("SSL_VERIFY", False)
TEMP_BUCKET=os.getenv("TEMP_BUCKET", None)

if SSL_VERIFY == 'false' or SSL_VERIFY is False:
    ssl_verify = False
else:
    ssl_verify = True



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

    key = event["key"]
    bucket = event["bucket"].split(":")[-1].split(".")[0]

    to_load_filename= "/tmp/org_list.json"
    
    # Download data from s3
    functions.download_file(key, to_load_filename, bucket)

    org_ids = functions.load_json(to_load_filename)

    return org_ids

