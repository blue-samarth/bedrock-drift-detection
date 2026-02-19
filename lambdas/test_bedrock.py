import boto3, json

bedrock = boto3.client('bedrock-runtime', region_name='us-west-2')

response = bedrock.invoke_model(
    modelId='anthropic.claude-3-5-sonnet-20240620-v1:0',
    body=json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 500,
        "messages": [{"role": "user", "content": "Write a Essay on Virender Sehwag"}]
    })
)

result = json.loads(response['body'].read())
print("✅ Bedrock working!")
print(result['content'][0]['text'])
