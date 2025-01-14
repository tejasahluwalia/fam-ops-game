import boto3
import json
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('game-sessions')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        session_id = body['session_id']
        player_id = body['player_id']
        
        # Get current session
        response = table.get_item(
            Key={'session_id': session_id}
        )
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Game session not found'})
            }
            
        session = response['Item']
        
        # Verify session is in WAITING status
        if session['status'] != 'WAITING':
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Game session is not in waiting state'})
            }
        
        # Add player to waiting list if not already present
        if player_id not in session['players_waiting']:
            session['players_waiting'].append(player_id)
            
        # Update DynamoDB
        table.update_item(
            Key={'session_id': session_id},
            UpdateExpression='SET players_waiting = :p, last_updated = :t',
            ExpressionAttributeValues={
                ':p': session['players_waiting'],
                ':t': datetime.utcnow().isoformat()
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'session_id': session_id,
                'server_name': session['server_name'],
                'host_id': session['host_id'],
                'players': session['players_waiting']
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
        