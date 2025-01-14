import boto3
import json
from datetime import datetime, timezone
import botocore.exceptions

dynamodb = boto3.resource('dynamodb')
gamelift = boto3.client('gamelift')
table = dynamodb.Table('game-sessions')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        session_id = body['session_id']
        host_id = body['host_id']
        
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
        
        # Verify host is making the request
        if session['host_id'] != host_id:
            return {
                'statusCode': 403,
                'body': json.dumps({'error': 'Only host can start the game'})
            }
        
        # Update status to CLAIMING
        table.update_item(
            Key={'session_id': session_id},
            UpdateExpression='SET #st = :s, last_updated = :t',
            ExpressionAttributeNames={
                '#st': 'status'  # Use expression attribute name for reserved keyword
            },
            ExpressionAttributeValues={
                ':s': 'CLAIMING',
                ':t': datetime.now(timezone.utc).isoformat()
            }
        )
        
        # Claim GameLift server
        game_server = gamelift.claim_game_server(
            GameServerGroupName='fam-ops-game-servers',
        )
        
        # Update DynamoDB with server details
        table.update_item(
            Key={'session_id': session_id},
            UpdateExpression='SET #st = :s, server_details = :d, last_updated = :t',
            ExpressionAttributeNames={
                '#st': 'status'  # Use expression attribute name for reserved keyword
            },
            ExpressionAttributeValues={
                ':s': 'ACTIVE',
                ':d': {
                    'connection_info': game_server['GameServer']['ConnectionInfo'],
                },
                ':t': datetime.now(timezone.utc).isoformat()
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'session_id': session_id,
                'server_details': {
                    'connection_info': game_server['GameServer']['ConnectionInfo'],
                }
            })
        }
        
    except (boto3.exceptions.Boto3Error, botocore.exceptions.BotoCoreError) as e: # import botocore.exceptions
        # If error occurs, revert status to WAITING
        if 'session_id' in locals():
            table.update_item(
                Key={'session_id': session_id},
                UpdateExpression='SET #st = :s, last_updated = :t',
                ExpressionAttributeNames={
                    '#st': 'status'  # Use expression attribute name for reserved keyword
                },
                ExpressionAttributeValues={
                    ':s': 'WAITING',
                    ':t': datetime.now(timezone.utc).isoformat()
                }
            )
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
