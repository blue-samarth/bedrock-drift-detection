import json, boto3
from datetime import datetime, timezone

ec2 = boto3.client('ec2')
s3 = boto3.client('s3')
dynamodb = boto3.client('dynamodb')
lambda_client = boto3.client('lambda')
events = boto3.client('events')
bedrock = boto3.client('bedrock')

def lambda_handler(event, context):
    try:
        actual = {
            'ec2_instances': get_ec2(),
            'dynamodb_tables': get_dynamodb(),
            's3_buckets': get_s3(),
            'lambda_functions': get_lambda(),
            'vpcs': get_vpcs(),
            'eventbridge_rules': get_eventbridge(),
            'bedrock_models': get_bedrock(),
            'timestamp': datetime.now(timezone.utc).isoformat()
        }
        actual['summary'] = {
            'ec2_count': len(actual['ec2_instances']),
            'dynamodb_count': len(actual['dynamodb_tables']),
            's3_count': len(actual['s3_buckets']),
            'lambda_count': len(actual['lambda_functions']),
            'vpc_count': len(actual['vpcs']),
            'eventbridge_count': len(actual['eventbridge_rules'])
        }
        return {'statusCode': 200, 'actual_state': actual}
    except Exception as e:
        return {'statusCode': 500, 'error': str(e)}

def get_ec2():
    instances = []
    for r in ec2.describe_instances()['Reservations']:
        for i in r['Instances']:
            instances.append({
                'id': i['InstanceId'],
                'instance_type': i['InstanceType'],
                'state': i['State']['Name']
            })
    return instances

def get_dynamodb():
    tables = []
    for name in dynamodb.list_tables().get('TableNames', []):
        info = dynamodb.describe_table(TableName=name)['Table']
        tables.append({'name': info['TableName'], 'status': info['TableStatus']})
    return tables

def get_s3():
    return [{'bucket': b['Name']} for b in s3.list_buckets().get('Buckets', [])]

def get_lambda():
    return [{'function_name': f['FunctionName']} for f in lambda_client.list_functions().get('Functions', [])]

def get_vpcs():
    return [{'id': v['VpcId']} for v in ec2.describe_vpcs().get('Vpcs', [])]

def get_eventbridge():
    return [{'name': r['Name']} for r in events.list_rules().get('Rules', [])]

def get_bedrock():
    try:
        return [{'model_id': m['modelId']} for m in bedrock.list_foundation_models().get('modelSummaries', [])]
    except:
        return []
