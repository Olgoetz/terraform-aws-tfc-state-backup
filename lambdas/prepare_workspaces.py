import json
import logging
from helpers import functions



logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """Prepares all workspaces from Terraform Cloud

        :param event: Incoming event object from AWS
        :param context: Context object from AWS
        :return: Bucket name and object key containing the workspace
    """

    print(json.dumps(event))

    key = event["key"]
    bucket = event["bucket"].split(":")[-1].split(".")[0]


    # Extract data
    tfc_org = key.split("/")[-1].split(".")[0]
    to_load_filename= f"/tmp/{tfc_org}.json"
    
    # Download data from s3
    functions.download_file(key, to_load_filename, bucket)

    # Load workspaces from file
    workspaces = functions.load_json(to_load_filename)

    return {
        "org_id": tfc_org,
        "ws": workspaces
    }


