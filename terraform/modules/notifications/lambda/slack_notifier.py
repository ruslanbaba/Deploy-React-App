import json
import urllib3
import os

def handler(event, context):
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    
    if not webhook_url:
        return {
            'statusCode': 200,
            'body': json.dumps('No Slack webhook configured')
        }
    
    # Parse SNS message
    message = json.loads(event['Records'][0]['Sns']['Message'])
    
    # Format Slack message
    slack_message = {
        "text": f"🚨 AWS Alert: {message.get('AlarmName', 'Unknown Alarm')}",
        "blocks": [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Alert:* {message.get('AlarmName', 'Unknown')}\n*Status:* {message.get('NewStateValue', 'Unknown')}\n*Reason:* {message.get('NewStateReason', 'No reason provided')}"
                }
            }
        ]
    }
    
    # Send to Slack
    http = urllib3.PoolManager()
    response = http.request(
        'POST',
        webhook_url,
        body=json.dumps(slack_message),
        headers={'Content-Type': 'application/json'}
    )
    
    return {
        'statusCode': response.status,
        'body': json.dumps(f'Message sent to Slack: {response.status}')
    }
