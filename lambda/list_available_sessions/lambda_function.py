import boto3
import json
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('game-sessions')

def lambda_handler(event, context):
    try:
        # Scan for WAITING status games
        # amazonq-ignore-next-line
        response = table.scan(
            FilterExpression='#status = :status',
            ExpressionAttributeNames={
                '#status': 'status'
            },
            ExpressionAttributeValues={
                ':status': 'WAITING'
            }
        )
        
        games = response['Items']
        
        # Filter out stale sessions (older than 30 minutes)
        current_time = datetime.utcnow()
        active_games = [
            game for game in games
            if current_time - datetime.fromisoformat(game['created_at']) < timedelta(minutes=30)
        ]
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'games': active_games
            })
        }
        
    except boto3.exceptions.Boto3Error as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'DynamoDB operation failed', 'details': str(e)})
        }
    except ValueError as e:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid date format', 'details': str(e)})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Unexpected error occurred', 'details': str(e)})
        }
