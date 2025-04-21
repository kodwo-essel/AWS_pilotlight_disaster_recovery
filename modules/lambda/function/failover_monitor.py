import os
import json
import time
import urllib3
import boto3

# HTTP client
http = urllib3.PoolManager()

# Environment variables
SECONDARY_REGION_NAME = os.environ.get("SECONDARY_REGION_NAME", "eu-west-2")  # fallback optional
PRIMARY_REGION_NAME = os.environ.get('PRIMARY_REGION_NAME', 'eu-west-1')
APP_HEALTH_URL = os.environ["APP_HEALTH_URL"]
RETRY_COUNT = int(os.environ.get("RETRY_COUNT", 3))
RETRY_INTERVAL = int(os.environ.get("RETRY_INTERVAL", 10))
ASG_NAME = os.environ["ASG_NAME"]
RDS_REPLICA_IDENTIFIER = os.environ["RDS_REPLICA_IDENTIFIER"]

# AWS clients
asg_client = boto3.client('autoscaling', region_name=SECONDARY_REGION_NAME)
rds_client = boto3.client('rds', region_name=SECONDARY_REGION_NAME)

def ping():
    try:
        response = http.request('GET', APP_HEALTH_URL, timeout=3.0)
        return response.status == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def trigger_failover():
    print("Triggering failover...")

    # Promote RDS Read Replica
    try:
        rds_client.promote_read_replica(
            DBInstanceIdentifier=RDS_REPLICA_IDENTIFIER
        )
        print("RDS replica promoted.")
    except Exception as e:
        print(f"RDS promotion failed: {e}")

    # Scale up Auto Scaling Group
    try:
        asg_client.update_auto_scaling_group(
            AutoScalingGroupName=ASG_NAME,
            MinSize=1,
            DesiredCapacity=1
        )
        print("ASG scaled up.")
    except Exception as e:
        print(f"ASG scale-up failed: {e}")

def lambda_handler(event, context):
    healthy = False

    for attempt in range(RETRY_COUNT):
        if ping():
            healthy = True
            print("Primary app is healthy.")
            break
        else:
            print(f"Health check attempt {attempt + 1} failed.")
            time.sleep(RETRY_INTERVAL)

    if not healthy:
        print("Primary region appears to be down. Initiating failover.")
        trigger_failover()
    else:
        print("No failover needed.")

    return {
        'statusCode': 200,
        'body': json.dumps('Heartbeat check complete.')
    }
