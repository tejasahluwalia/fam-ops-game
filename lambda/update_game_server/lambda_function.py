import boto3
import json
from datetime import datetime, timezone

gamelift = boto3.client('gamelift')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('game-sessions')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        server_id = body['server_id']
        session_id = body.get('session_id')
        player_count = body.get('player_count', 0)
        health_status = body.get('health_status', 'HEALTHY')
        
        # Determine utilization status based on player count
        utilization_status = 'UTILIZED' if player_count > 0 else 'AVAILABLE'
        
        # Update GameLift server status
        response = gamelift.update_game_server(
            GameServerGroupName='fam-ops-game-servers',
            GameServerId=server_id,
            HealthCheck=health_status,
            UtilizationStatus=utilization_status,
            GameServerData=json.dumps({
                'last_updated': datetime.now(timezone.utc).isoformat(),
                'player_count': player_count,
                'session_id': session_id
            })
        )
        
        # If session_id is provided, update DynamoDB
        if session_id:
            table.update_item(
                Key={'session_id': session_id},
                UpdateExpression='SET server_details.player_count = :pc, last_updated = :t',
                ExpressionAttributeValues={
                    ':pc': player_count,
                    ':t': datetime.now(timezone.utc).isoformat()
                }
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Game server updated successfully',
                'server_id': server_id,
                'utilization_status': utilization_status,
                'health_status': health_status,
                'player_count': player_count
            })
        }
        
    except boto3.exceptions.Boto3Error as e:
        logger.error(f"Boto3 error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'An error occurred while updating the game server'
            })
        }
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}", exc_info=True)
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'An unexpected error occurred'
            })
        }
