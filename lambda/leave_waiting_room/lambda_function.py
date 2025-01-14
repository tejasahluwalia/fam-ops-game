import boto3
import json
from datetime import datetime, timezone
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('game-sessions')

def lambda_handler(event, context):
    try:
        # Extract data from event
        body = json.loads(event['body'])
        session_id = body['session_id']
        player_id = body['player_id']
        
        # Get the current session
        response = table.get_item(
            Key={
                'session_id': session_id
            }
        )
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Game session not found'
                })
            }
            
        session = response['Item']
        
        # Check if player is in the waiting room
        if player_id not in session['players_waiting']:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Player is not in the waiting room'
                })
            }
        
        # Remove player from waiting room
        players_waiting = [p for p in session['players_waiting'] if p != player_id]
        
        # If host leaves, and there are other players, assign new host
        new_host_id = session['host_id']
        if player_id == session['host_id'] and players_waiting:
            new_host_id = players_waiting[0]
        
        # If no players left, delete the session
        if not players_waiting:
            table.delete_item(
                Key={
                    'session_id': session_id
                }
            )
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Game session deleted as no players remaining',
                    'session_id': session_id
                })
            }
        
        # Update the session
        table.update_item(
            Key={
                'session_id': session_id
            },
            UpdateExpression='SET players_waiting = :players, host_id = :host, last_updated = :time',
            ExpressionAttributeValues={
                ':players': players_waiting,
                ':host': new_host_id,
                ':time': datetime.now(timezone.utc).isoformat()
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully left waiting room',
                'session_id': session_id,
                'remaining_players': players_waiting,
                'new_host': new_host_id
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
