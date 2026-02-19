import json, boto3, os
from datetime import datetime, timezone
from typing import Dict, Any

s3, dynamodb = boto3.client('s3'), boto3.client('dynamodb')

def lambda_handler(event, context):
    try:
        state_data = read_state(os.environ['TF_STATE_BUCKET'], 'test/terraform.tfstate')
        desired = extract_state(state_data)
        locks = check_locks(os.environ['TF_LOCK_TABLE'])
        
        return {
            'statusCode': 200,
            'desired_state': desired,
            'lock_status': locks,
            'timestamp': datetime.now(timezone.utc).isoformat()
        }
    except Exception as e:
        return {'statusCode': 500, 'error': str(e)}

def read_state(bucket, key):
    return json.loads(s3.get_object(Bucket=bucket, Key=key)['Body'].read())

def extract_state(data):
    desired = {
        'ec2_instances': [], 'dynamodb_tables': [], 's3_buckets': [],
        'lambda_functions': [], 'vpcs': [], 'eventbridge_rules': [],
        'summary': {'ec2_count': 0, 'dynamodb_count': 0, 's3_count': 0,
                   'lambda_count': 0, 'vpc_count': 0, 'eventbridge_count': 0}
    }
    
    for res in data.get('resources', []):
        rtype = res.get('type', '')
        for inst in res.get('instances', []):
            attr = inst.get('attributes', {})
            
            if rtype == 'aws_instance':
                desired['ec2_instances'].append({
                    'id': attr.get('id', '')[-8:],
                    'instance_type': attr.get('instance_type'),
                    'state': attr.get('instance_state')
                })
                desired['summary']['ec2_count'] += 1
            elif rtype == 'aws_dynamodb_table':
                desired['dynamodb_tables'].append({'name': attr.get('name')})
                desired['summary']['dynamodb_count'] += 1
            elif rtype == 'aws_s3_bucket':
                desired['s3_buckets'].append({'bucket': attr.get('bucket')})
                desired['summary']['s3_count'] += 1
            elif rtype == 'aws_lambda_function':
                desired['lambda_functions'].append({'function_name': attr.get('function_name')})
                desired['summary']['lambda_count'] += 1
            elif rtype == 'aws_vpc':
                desired['vpcs'].append({'id': attr.get('id', '')[-8:]})
                desired['summary']['vpc_count'] += 1
            elif rtype == 'aws_cloudwatch_event_rule':
                desired['eventbridge_rules'].append({'name': attr.get('name')})
                desired['summary']['eventbridge_count'] += 1
    
    return desired

def check_locks(table):
    try:
        dynamodb.describe_table(TableName=table)
        items = dynamodb.scan(TableName=table, Limit=10).get('Items', [])
        return {
            'table_exists': True,
            'active_locks': len(items),
            'locks': [{'lock_id': i.get('LockID', {}).get('S', '')} for i in items]
        }
    except:
        return {'table_exists': False}
