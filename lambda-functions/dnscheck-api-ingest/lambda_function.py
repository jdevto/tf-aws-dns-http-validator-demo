import json
import os
import uuid
import boto3
from datetime import datetime

eventbridge = boto3.client('events')

def lambda_handler(event, context):
    """API Gateway handler that validates input and emits ValidationRequested event"""

    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})

        target = body.get('target', '').strip()

        if not target:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Missing required field: target'
                })
            }

        # Max targets limit from environment
        max_targets = int(os.environ.get('MAX_TARGETS', '10'))

        # Validate target count (for future multi-target support)
        targets = [t.strip() for t in target.split(',') if t.strip()]
        if len(targets) > max_targets:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': f'Maximum {max_targets} targets allowed per request'
                })
            }

        # Generate request ID
        request_id = str(uuid.uuid4())

        # Emit ValidationRequested event
        eventbus_name = os.environ.get('EVENTBUS_NAME', 'dns-checks')

        eventbridge.put_events(
            Entries=[{
                'Source': 'dnscheck.api-ingest',
                'DetailType': 'ValidationRequested',
                'Detail': json.dumps({
                    'requestId': request_id,
                    'target': target,
                    'timestamp': datetime.utcnow().isoformat() + 'Z'
                }),
                'EventBusName': eventbus_name
            }]
        )

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'requestId': request_id,
                'target': target,
                'status': 'accepted'
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
