import boto3
import json
import os
from datetime import datetime, timezone

gamelift = boto3.client('gamelift')

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        instance_id = body['instance_id']
        server_id = body['server_id']  # Unique ID for this game server
        port = str(body.get('port', 6060))  # Game server port
        public_hostname = body.get('public_hostname')  # Public hostname of the instance
        
        # Register the game server with GameLift
        response = gamelift.register_game_server(
            GameServerGroupName='fam-ops-game-servers',
            GameServerId=server_id,
            InstanceId=instance_id,
            ConnectionInfo=f'{public_hostname + ':' + port}',  # GameLift will use instance IP + this port
            GameServerData=json.dumps({
                'start_time': datetime.now(timezone.utc).isoformat(),
                'status': 'AVAILABLE'
            })
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Game server registered successfully',
                'server_id': server_id
            })
        }
        
    except boto3.exceptions.Boto3Error as e:
        print(f"Boto3 error occurred: {str(e)}") # import logging
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'An error occurred while registering the game server'
            })
        }
    except Exception as e:
        print(f"Unexpected error occurred: {str(e)}") # import logging
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'An unexpected error occurred'
            })
        }
