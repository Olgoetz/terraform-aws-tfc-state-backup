import json
import boto3
import os
import logging

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
    response = s3_client.upload_file(file_name, bucket, object_name)

    return response


def download_file(object_name, file_name, bucket):
    """Dowload a file from an S3 bucket
    
    :param file_name: Filename to save the fail to
    :param object_name: Filen to download
    :param bucket: Bucket to download from
    :return: True if file was downloaded, else False
    """

    s3 = boto3.client('s3')
    response = s3.download_file(bucket, object_name, file_name)

    return response

def load_json(file_name):
    """Load file as json
    
    :param file_name: Path to json file
    :return: json ddata
    """

    with open(file_name, 'r') as f:
        data = json.load(f)

    return data

def save_json(file_name, content):
    """Save data as json file
    
    :param file_name: Name of the json file
    :param content: Content to be saved as json
    :return: True if successful else False
    """

    try:
        with open(file_name, 'w') as json_file:
            json.dump(content, json_file)
    except TypeError:
        logger.error("Unable to serialize the object")
        return False
    return True