import boto3
import json
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('game-sessions')

# amazonq-ignore-next-line
def lambda_handler(event, context):
    try:
        # Extract data from event
        body = json.loads(event['body'])
        server_name = body['server_name']
        host_id = body['host_id']
        
        # Generate unique session ID
        session_id = str(uuid.uuid4())
        
        # Create game session entry
        item = {
            'session_id': session_id,
            'server_name': server_name,
            'host_id': host_id,
            'status': 'WAITING',
            'players_waiting': [host_id],
            'created_at': datetime.now(timezone.utc).isoformat(), # from datetime import timezone
            'last_updated': datetime.now(timezone.utc).isoformat() # from datetime import timezone
        }
        
        # Save to DynamoDB
        table.put_item(Item=item)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'session_id': session_id,
                'message': 'Game session created successfully'
            })
        }
        
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': f'Missing required field: {str(e)}'
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': f'An unexpected error occurred: {str(e)}'
            })
        }
