import boto3
import json
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb')
gamelift = boto3.client('gamelift')
table = dynamodb.Table('game-sessions')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        session_id = body['session_id']
        server_id = body['server_id']
        
        # Deregister from GameLift
        gamelift.deregister_game_server(
            GameServerGroupName='fam-ops-game-servers',
            GameServerId=server_id
        )
        
        # Update DynamoDB status
        table.update_item(
            Key={'session_id': session_id},
            UpdateExpression='SET #st = :s, last_updated = :t',
            ExpressionAttributeValues={
                '#st': 'status',
                ':s': 'ENDED',
                ':t': datetime.now(timezone.utc).isoformat()
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Game server deregistered successfully'
            })
        }
        
    except boto3.exceptions.Boto3Error as e:
        print(f"Boto3 error occurred: {str(e)}")  # Log the full exception details
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'AWS service error occurred'})
        }
    except json.JSONDecodeError as e:
        print(f"JSON decode error: {str(e)}")  # Log the full exception details
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid JSON in request body'})
        }
    except Exception as e:
        print(f"Unexpected error: {str(e)}")  # Log the full exception details
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'An unexpected error occurred'})
        }
