import os
import boto3
import csv
import json

def handler(event, context):
    s3_bucket = event['Records'][0]['s3']['bucket']['name']
    s3_key = event['Records'][0]['s3']['object']['key']
    
    s3_client = boto3.client('s3')
    sns_client = boto3.client('sns')
    
    try:
        response = s3_client.get_object(Bucket=s3_bucket, Key=s3_key)
        
        # Use StreamingBody to read the CSV file in chunks
        with response['Body'] as csvfile:
            csv_reader = csv.DictReader(csvfile.read().decode('utf-8').splitlines())
            
            for row in csv_reader:
                # Convert each row to a JSON string
                json_string = json.dumps(row)
                
                # Publish the JSON string to the SNS topic
                topic_arn = os.environ['SNS_TOPIC_ARN']
                sns_client.publish(TopicArn=topic_arn, Message=json_string)
        
    except Exception as e:
        print(f"Error reading or processing CSV file: {e}")
