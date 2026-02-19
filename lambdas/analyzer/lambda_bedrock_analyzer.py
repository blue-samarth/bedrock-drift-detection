import json
import boto3
import os
from datetime import datetime, timezone

lambda_client = boto3.client("lambda")
bedrock_runtime = boto3.client("bedrock-runtime")
s3 = boto3.client("s3")

# ---------------------------
# Lambda Handler
# ---------------------------
def lambda_handler(event, context):
    try:
        desired_resp = invoke_lambda(os.environ["TF_STATE_LAMBDA_NAME"])
        actual_resp = invoke_lambda(os.environ["LIVE_COLLECTOR_LAMBDA_NAME"])

        desired = desired_resp["desired_state"]
        actual = actual_resp["actual_state"]
        locks = desired_resp.get("lock_status", {})

        drift = calc_drift(desired, actual)
        analysis = invoke_bedrock(desired, actual, locks, drift)

        report = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "desired_summary": desired["summary"],
            "actual_summary": actual["summary"],
            "drift": drift,
            "lock_status": locks,
            "bedrock_analysis": analysis,
        }

        store_report(report)

        return {
            "statusCode": 200,
            "message": "Drift analysis completed",
            "report_key": report["s3_key"]
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "error": str(e)
        }

# ---------------------------
# Invoke Child Lambdas
# ---------------------------
def invoke_lambda(function_name):
    resp = lambda_client.invoke(
        FunctionName=function_name,
        InvocationType="RequestResponse"
    )

    payload = json.loads(resp["Payload"].read())

    if payload.get("statusCode") != 200:
        raise RuntimeError(f"{function_name} failed: {payload}")

    return payload

# ---------------------------
# Drift Calculation
# ---------------------------
def calc_drift(desired, actual):
    drift = {
        "has_drift": False,
        "resource_drifts": {}
    }

    mapping = [
        ("ec2_count", "EC2"),
        ("dynamodb_count", "DynamoDB"),
        ("s3_count", "S3"),
        ("lambda_count", "Lambda"),
        ("vpc_count", "VPC"),
        ("eventbridge_count", "EventBridge"),
    ]

    for key, name in mapping:
        d = desired["summary"].get(key, 0)
        a = actual["summary"].get(key, 0)

        if d != a:
            drift["has_drift"] = True
            drift["resource_drifts"][name] = {
                "desired": d,
                "actual": a,
                "difference": a - d
            }

    return drift

# ---------------------------
# Bedrock Invocation (Your Logic)
# ---------------------------
def invoke_bedrock(desired, actual, locks, drift):
    prompt = f"""AWS infrastructure drift analysis.

DESIRED: {json.dumps(desired.get('summary', {}))}
ACTUAL: {json.dumps(actual.get('summary', {}))}
DRIFT: {json.dumps(drift)}
LOCKS: {json.dumps(locks)}

Return ONLY valid JSON with:
drift_severity, drift_explanation, lock_health,
availability_risk, cost_impact, recommended_actions, summary
"""

    resp = bedrock_runtime.invoke_model(
        modelId=os.environ["BEDROCK_MODEL_ID"],
        body=json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1500,
            "temperature": 0.2,
            "messages": [{"role": "user", "content": prompt}]
        })
    )

    raw = resp["body"].read()
    parsed = json.loads(raw)
    text = parsed["content"][0]["text"]

    if "```" in text:
        text = text.split("```")[1]

    return json.loads(text)

# ---------------------------
# Store Report
# ---------------------------
def store_report(report):
    bucket = os.environ["RESULTS_BUCKET"].strip()
    key = f"reports/{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}_drift.json"

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(report, indent=2)
    )

    report["s3_key"] = f"s3://{bucket}/{key}"
