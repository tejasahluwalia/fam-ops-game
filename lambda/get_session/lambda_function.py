import boto3
import json
from datetime import datetime, timezone
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('game-sessions')

def lambda_handler(event, context):
    try:
        # Get session_id from request
        body = json.loads(event['body'])
        session_id = body['session_id']
        
        # Get current session data
        response = table.get_item(
            Key={'session_id': session_id}
        )
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Game session not found'})
            }
            
        session = response['Item']
        
        # Prepare response data
        session_data = {
            'session_id': session['session_id'],
            'server_name': session['server_name'],
            'status': session['status'],
            'host_id': session['host_id'],
            'players': session['players_waiting'],
            'last_updated': session['last_updated']
        }
        
        # Include server details if game is active
        if session['status'] == 'ACTIVE' and 'server_details' in session:
            session_data['server_details'] = session['server_details']
            
        return {
            'statusCode': 200,
            'body': json.dumps(session_data)
        }
        
    except KeyError as e:
        print(f"Missing required field: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': f"Missing required field: {str(e)}"
            })
        }
    except ClientError as e:
        print(f"DynamoDB error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Database error occurred'
            })
        }
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'An unexpected error occurred'
            })
        }
