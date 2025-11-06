import json
import os
import socket
import boto3
from datetime import datetime

eventbridge = boto3.client('events')

def lambda_handler(event, context):
    """Resolves DNS and emits DNSResolved or DNSFailed event"""

    try:
        # Parse EventBridge event
        # Handle both string and dict formats
        if isinstance(event.get('detail'), str):
            detail = json.loads(event['detail'])
        else:
            detail = event.get('detail', {})

        request_id = detail.get('requestId', '')
        target = detail.get('target', '')

        # Timeout from environment (seconds)
        timeout = int(os.environ.get('DNS_TIMEOUT', '5'))

        start_time = datetime.utcnow()

        # Resolve DNS
        try:
            socket.setdefaulttimeout(timeout)
            ip_addresses = socket.gethostbyname_ex(target)
            ip_list = ip_addresses[2] if len(ip_addresses) > 2 else []

            end_time = datetime.utcnow()
            duration_ms = int((end_time - start_time).total_seconds() * 1000)

            # Emit DNSResolved event
            eventbus_name = os.environ.get('EVENTBUS_NAME', 'dns-checks')

            eventbridge.put_events(
                Entries=[{
                    'Source': 'dnscheck.dns-resolver',
                    'DetailType': 'DNSResolved',
                    'Detail': json.dumps({
                        'requestId': request_id,
                        'target': target,
                        'status': 'ok',
                        'ipAddresses': ip_list,
                        'timings': {
                            'dns': duration_ms
                        },
                        'timestamp': end_time.isoformat() + 'Z'
                    }),
                    'EventBusName': eventbus_name
                }]
            )

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'requestId': request_id,
                    'status': 'resolved',
                    'ipAddresses': ip_list
                })
            }

        except socket.gaierror as e:
            # DNS resolution failed
            end_time = datetime.utcnow()
            duration_ms = int((end_time - start_time).total_seconds() * 1000)

            eventbus_name = os.environ.get('EVENTBUS_NAME', 'dns-checks')

            eventbridge.put_events(
                Entries=[{
                    'Source': 'dnscheck.dns-resolver',
                    'DetailType': 'DNSFailed',
                    'Detail': json.dumps({
                        'requestId': request_id,
                        'target': target,
                        'status': 'fail',
                        'reason': f'DNS resolution failed: {str(e)}',
                        'timings': {
                            'dns': duration_ms
                        },
                        'timestamp': end_time.isoformat() + 'Z'
                    }),
                    'EventBusName': eventbus_name
                }]
            )

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'requestId': request_id,
                    'status': 'failed',
                    'reason': str(e)
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
