import json
import os
import boto3
from decimal import Decimal
from datetime import datetime

dynamodb = boto3.resource('dynamodb')

def decimal_default(obj):
    """Convert Decimal to int/float for JSON serialization"""
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError

def lambda_handler(event, context):
    """API Gateway handler for status queries"""

    try:
        table_name = os.environ.get('DYNAMODB_TABLE', 'dnscheck-validations')
        table = dynamodb.Table(table_name)

        # Parse query parameters
        # API Gateway HTTP API v2: path can be in event['path'] or requestContext.http.path
        path = event.get('path', '') or event.get('requestContext', {}).get('http', {}).get('path', '') or event.get('rawPath', '')
        query_params = event.get('queryStringParameters') or {}

        if path == '/status' or path.endswith('/status'):
            # GET /status?requestId=...
            request_id = query_params.get('requestId', '')

            if not request_id:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'error': 'Missing required parameter: requestId'
                    })
                }

            # Query all steps for this request
            response = table.query(
                KeyConditionExpression='requestId = :rid',
                ExpressionAttributeValues={
                    ':rid': request_id
                }
            )

            items = response['Items']

            # Separate summary from steps
            summary = None
            steps = []

            for item in items:
                if item['step'] == 'SUMMARY':
                    summary = item
                else:
                    steps.append(item)

            # Sort steps by timestamp
            steps.sort(key=lambda x: x.get('ts', ''))

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'requestId': request_id,
                    'summary': summary,
                    'steps': steps
                }, default=decimal_default)
            }

        elif path == '/recent' or path.endswith('/recent'):
            # GET /recent?target=...
            target = query_params.get('target', '')

            if not target:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    'body': json.dumps({
                        'error': 'Missing required parameter: target'
                    })
                }

            # Query GSI byTarget
            response = table.query(
                IndexName='byTarget',
                KeyConditionExpression='target = :target AND begins_with(#time, :prefix)',
                ExpressionAttributeNames={
                    '#time': 'time'
                },
                ExpressionAttributeValues={
                    ':target': target,
                    ':prefix': '202'  # Rough filter for recent (202x dates)
                },
                ScanIndexForward=False,  # Descending order
                Limit=10
            )

            # Get only SUMMARY items
            summaries = [item for item in response['Items'] if item['step'] == 'SUMMARY']

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'target': target,
                    'recent': summaries
                }, default=decimal_default)
            }

        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Not found'
                })
            }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }
