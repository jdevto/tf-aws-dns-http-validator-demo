import json
import os
import boto3
from datetime import datetime

eventbridge = boto3.client('events')
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    """Aggregates all validation events, writes to DynamoDB, and emits final status"""

    try:
        # Parse EventBridge event
        # Handle both string and dict formats
        if isinstance(event.get('detail'), str):
            detail = json.loads(event['detail'])
        else:
            detail = event.get('detail', {})

        request_id = detail.get('requestId', '')
        detail_type = event.get('detail-type', '')
        target = detail.get('target', '')

        table_name = os.environ.get('DYNAMODB_TABLE', 'dnscheck-validations')
        table = dynamodb.Table(table_name)

        # Write step result to DynamoDB
        step_name = detail_type.lower()
        status = detail.get('status', 'unknown')
        reason = detail.get('reason', '')
        timings = detail.get('timings', {})
        timestamp = detail.get('timestamp', datetime.utcnow().isoformat() + 'Z')

        # Store step item
        table.put_item(
            Item={
                'requestId': request_id,
                'step': step_name,
                'status': status,
                'reason': reason,
                'timings': timings,
                'ts': timestamp,
                'target': target,
                'time': timestamp
            }
        )

        # Check if we have all required events
        # Query for all steps for this request
        response = table.query(
            KeyConditionExpression='requestId = :rid',
            ExpressionAttributeValues={
                ':rid': request_id
            }
        )

        steps = {item['step']: item for item in response['Items']}

        # Determine if validation is complete
        # We need: DNSResolved or DNSFailed, HTTPChecked, HTTPSChecked
        dns_complete = 'dnsresolved' in steps or 'dnsfailed' in steps
        dns_failed = 'dnsfailed' in steps

        http_complete = 'httpchecked' in steps
        https_complete = 'httpschecked' in steps

        # If DNS failed, HTTP/HTTPS won't run, so we're done
        # Otherwise, we need all three steps
        all_complete = dns_complete and (dns_failed or (http_complete and https_complete))

        if all_complete:
            # Determine overall status
            overall_status = 'ok'
            if steps.get('dnsfailed', {}).get('status') == 'fail':
                overall_status = 'fail'
            elif any(steps.get(s, {}).get('status') == 'fail' for s in ['httpchecked', 'httpschecked']):
                overall_status = 'fail'
            elif any(steps.get(s, {}).get('status') == 'warn' for s in ['httpchecked', 'httpschecked']):
                overall_status = 'warn'

            # Get start and end times
            timestamps = [item.get('ts', '') for item in steps.values() if item.get('ts')]
            started_at = min(timestamps) if timestamps else timestamp
            finished_at = timestamp

            # Store summary
            table.put_item(
                Item={
                    'requestId': request_id,
                    'step': 'SUMMARY',
                    'target': target,
                    'startedAt': started_at,
                    'finishedAt': finished_at,
                    'overallStatus': overall_status,
                    'ts': finished_at,
                    'time': finished_at
                }
            )

            # Emit final event
            eventbus_name = os.environ.get('EVENTBUS_NAME', 'dns-checks')

            if overall_status == 'ok':
                event_type = 'ValidationCompleted'
            else:
                event_type = 'ValidationFailed'

            eventbridge.put_events(
                Entries=[{
                    'Source': 'dnscheck.aggregator',
                    'DetailType': event_type,
                    'Detail': json.dumps({
                        'requestId': request_id,
                        'target': target,
                        'status': overall_status,
                        'startedAt': started_at,
                        'finishedAt': finished_at,
                        'timestamp': finished_at
                    }),
                    'EventBusName': eventbus_name
                }]
            )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'requestId': request_id,
                'step': step_name,
                'status': status,
                'allComplete': all_complete
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }
