import json
import os
import ipaddress

def lambda_handler(event, context):
    """
    Lambda authorizer for API Gateway v2 that validates source IP addresses.

    Expected environment variables:
    - ALLOWED_IPS: Comma-separated list of IP addresses/CIDR blocks to allow
    """

    # Get request ID for context
    request_id = event.get('requestContext', {}).get('requestId', 'unknown')

    # Get allowed IPs from environment variable
    allowed_ips_str = os.environ.get('ALLOWED_IPS', '')
    if not allowed_ips_str:
        # Default deny if no allowed IPs configured
        return generate_policy('Deny', request_id)

    # Parse allowed IPs
    allowed_ips = [ip.strip() for ip in allowed_ips_str.split(',') if ip.strip()]

    # Extract source IP from request context (HTTP API v2 format)
    request_context = event.get('requestContext', {})
    source_ip = request_context.get('http', {}).get('sourceIp')

    if not source_ip:
        # If we can't determine the source IP, deny
        return generate_policy('Deny', request_id)

    # Check if source IP is in allowed list
    try:
        source_ip_addr = ipaddress.ip_address(source_ip)
        is_allowed = False

        for allowed_ip in allowed_ips:
            try:
                # Try as CIDR block first
                if '/' in allowed_ip:
                    network = ipaddress.ip_network(allowed_ip, strict=False)
                    if source_ip_addr in network:
                        is_allowed = True
                        break
                else:
                    # Try as single IP
                    allowed_ip_addr = ipaddress.ip_address(allowed_ip)
                    if source_ip_addr == allowed_ip_addr:
                        is_allowed = True
                        break
            except (ValueError, ipaddress.AddressValueError):
                # Invalid IP format in allowed list, skip
                continue

        if is_allowed:
            return generate_policy('Allow', request_id)
        else:
            return generate_policy('Deny', request_id)

    except (ValueError, ipaddress.AddressValueError):
        # Invalid source IP format, deny
        return generate_policy('Deny', request_id)


def generate_policy(effect, request_id):
    """Generate an IAM policy for API Gateway HTTP API v2 REQUEST authorizer"""
    # HTTP API v2 uses IAM policy format for REQUEST authorizers
    policy_document = {
        'Version': '2012-10-17',
        'Statement': [
            {
                'Action': 'execute-api:Invoke',
                'Effect': effect,
                'Resource': '*'  # HTTP API v2 doesn't support resource-level policies
            }
        ]
    }

    return {
        'principalId': 'user',
        'policyDocument': policy_document,
        'context': {
            'requestId': request_id
        }
    }
