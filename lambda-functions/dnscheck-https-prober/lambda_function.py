import json
import os
import urllib.request
import urllib.error
import ssl
import boto3
from datetime import datetime

eventbridge = boto3.client('events')

def lambda_handler(event, context):
    """Checks HTTPS endpoint and emits HTTPSChecked event"""

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
        timeout = int(os.environ.get('HTTPS_TIMEOUT', '10'))

        start_time = datetime.utcnow()

        # Try HTTPS on first IP
        https_url = f"https://{target}"
        status_code = None
        error_message = None
        ssl_valid = None

        try:
            # Create SSL context
            ctx = ssl.create_default_context()

            req = urllib.request.Request(https_url)
            req.add_header('User-Agent', 'dnscheck-https-prober/1.0')

            with urllib.request.urlopen(req, timeout=timeout, context=ctx) as response:
                status_code = response.getcode()
                ssl_valid = True

        except ssl.SSLError as e:
            ssl_valid = False
            error_message = f"SSL error: {str(e)}"
        except urllib.error.HTTPError as e:
            status_code = e.code
            ssl_valid = True  # SSL worked, but HTTP error
            if status_code >= 400:
                error_message = f"HTTP {status_code}"
        except urllib.error.URLError as e:
            error_message = str(e.reason) if hasattr(e, 'reason') else str(e)
            ssl_valid = False
        except Exception as e:
            error_message = str(e)
            ssl_valid = False

        end_time = datetime.utcnow()
        duration_ms = int((end_time - start_time).total_seconds() * 1000)

        # Determine status
        if ssl_valid and status_code and 200 <= status_code < 400:
            status = 'ok'
        elif ssl_valid and status_code and status_code >= 400:
            status = 'warn'
            error_message = f"HTTP {status_code}"
        elif not ssl_valid:
            status = 'fail'
            error_message = error_message or 'SSL validation failed'
        else:
            status = 'fail'
            error_message = error_message or 'Connection failed'

        # Emit HTTPSChecked event
        eventbus_name = os.environ.get('EVENTBUS_NAME', 'dns-checks')

        event_detail = {
            'requestId': request_id,
            'target': target,
            'status': status,
            'timings': {
                'https': duration_ms
            },
            'timestamp': end_time.isoformat() + 'Z'
        }

        if status_code:
            event_detail['httpStatusCode'] = status_code

        if ssl_valid is not None:
            event_detail['sslValid'] = ssl_valid

        if error_message:
            event_detail['reason'] = error_message

        eventbridge.put_events(
            Entries=[{
                'Source': 'dnscheck.https-prober',
                'DetailType': 'HTTPSChecked',
                'Detail': json.dumps(event_detail),
                'EventBusName': eventbus_name
            }]
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'requestId': request_id,
                'status': status,
                'statusCode': status_code,
                'sslValid': ssl_valid
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
