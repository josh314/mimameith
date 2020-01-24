#!/usr/bin/python3

import sys
import boto3

S3_BUCKET = sys.argv[1]

s3 = boto3.client('s3')

resp = s3.list_objects_v2(Bucket=S3_BUCKET)

latest_object = sorted(resp['Contents'], key=lambda x: x['LastModified'], reverse=True )[0]

print(latest_object['Key'])
