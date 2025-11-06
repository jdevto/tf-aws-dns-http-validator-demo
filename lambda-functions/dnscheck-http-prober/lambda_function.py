import json
import os
import urllib.request
import urllib.error
import boto3
from datetime import datetime

eventbridge = boto3.client('events')

def lambda_handler(event, context):
    """Checks HTTP endpoint and emits HTTPChecked event"""

    try:
        # Parse EventBridge event
        # Handle both string and dict formats
        if isinstance(event.get('detail'), str):
            detail = json.loads(event['detail'])
        else:
            detail = event.get('detail', {})

        request_id = detail.get('requestId', '')
        target = detail.get('target', '')
        ip_addresses = detail.get('ipAddresses', [])

        if not ip_addresses:
            # No IPs to check
            return {
                'statusCode': 200,
                'body': json.dumps({'message': 'No IP addresses to check'})
            }

        # Timeout from environment (seconds)
        timeout = int(os.environ.get('HTTP_TIMEOUT', '10'))

        start_time = datetime.utcnow()

        # Try HTTP on first IP
        http_url = f"http://{target}"
        status_code = None
        error_message = None

        try:
            req = urllib.request.Request(http_url)
            req.add_header('User-Agent', 'dnscheck-http-prober/1.0')

            with urllib.request.urlopen(req, timeout=timeout) as response:
                status_code = response.getcode()

        except urllib.error.HTTPError as e:
            status_code = e.code
            if status_code >= 400:
                error_message = f"HTTP {status_code}"
        except urllib.error.URLError as e:
            error_message = str(e.reason) if hasattr(e, 'reason') else str(e)
        except Exception as e:
            error_message = str(e)

        end_time = datetime.utcnow()
        duration_ms = int((end_time - start_time).total_seconds() * 1000)

        # Determine status
        if status_code and 200 <= status_code < 400:
            status = 'ok'
        elif status_code and status_code >= 400:
            status = 'warn'
            error_message = f"HTTP {status_code}"
        else:
            status = 'fail'
            error_message = error_message or 'Connection failed'

        # Emit HTTPChecked event
        eventbus_name = os.environ.get('EVENTBUS_NAME', 'dns-checks')

        event_detail = {
            'requestId': request_id,
            'target': target,
            'status': status,
            'timings': {
                'http': duration_ms
            },
            'timestamp': end_time.isoformat() + 'Z'
        }

        if status_code:
            event_detail['httpStatusCode'] = status_code

        if error_message:
            event_detail['reason'] = error_message

        eventbridge.put_events(
            Entries=[{
                'Source': 'dnscheck.http-prober',
                'DetailType': 'HTTPChecked',
                'Detail': json.dumps(event_detail),
                'EventBusName': eventbus_name
            }]
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'requestId': request_id,
                'status': status,
                'statusCode': status_code
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
