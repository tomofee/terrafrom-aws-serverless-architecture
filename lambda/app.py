import json
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('TodoTable')

def lambda_handler(event, context):
    method = event.get("httpMethod")

    if method == "GET":
        items = table.scan()
        return {
            "statusCode": 200,
            "body": json.dumps(items["Items"])
        }

    if method == "POST":
        body = json.loads(event["body"])
        item = {
            "id": str(uuid.uuid4()),
            "task": body["task"]
        }
        table.put_item(Item=item)
        return {
            "statusCode": 200,
            "body": json.dumps(item)
        }

    if method == "DELETE":
        body = json.loads(event["body"])
        table.delete_item(
            Key={"id": body["id"]}
        )
        return {
            "statusCode": 200,
            "body": json.dumps({"deleted": body["id"]})
        }

    return {"statusCode": 400, "body": "Unsupported Method"}
