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
SECONDARY_APP_HEALTH_URL = os.environ["SECONDARY_APP_HEALTH_URL"]
RETRY_COUNT = int(os.environ.get("RETRY_COUNT", 3))
RETRY_INTERVAL = int(os.environ.get("RETRY_INTERVAL", 10))
ASG_NAME = os.environ["ASG_NAME"]
RDS_REPLICA_IDENTIFIER = os.environ["RDS_REPLICA_IDENTIFIER"]
EMAIL_ADDRESS = os.environ["EMAIL_ADDRESS"]

# AWS clients
asg_client = boto3.client('autoscaling', region_name=SECONDARY_REGION_NAME)
rds_client = boto3.client('rds', region_name=SECONDARY_REGION_NAME)
ses_client = boto3.client('ses', region_name=SECONDARY_REGION_NAME)

def ping():
    try:
        response = http.request('GET', APP_HEALTH_URL, timeout=3.0)
        dr_response = http.request('GET', SECONDARY_APP_HEALTH_URL, timeout=3.0)
        return (response.status == 200) or (dr_response.status == 200)
    except Exception as e:
        print(f"Health check failed: {e}")
        return False
    

# SEND email with SES
def send_email_with_ses(sender, recipient, subject, body_text):
    try:
        response = ses_client.send_email(
            Source=sender,
            Destination={'ToAddresses': [recipient]},
            Message={
                'Subject': {'Data': subject},
                'Body': {
                    'Text': {'Data': body_text}
                }
            }
        )
        print("Email sent! Message ID:", response['MessageId'])
        return response
    except Exception as e:
        print(f"Error sending email: {e}")
        return None

def trigger_failover():
    print("Triggering failover...")

    # Email Notification of failoverprimary failure and start of failover
    send_email_with_ses(
        sender=EMAIL_ADDRESS,
        recipient=EMAIL_ADDRESS,
        subject="Application Down. Failover Initiated",
        body_text="Hello, the primary system for the pilot light failover application is down and automatic failover has been initiated."
    )


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


    # Email confirmation of successful failover
    send_email_with_ses(
        sender=EMAIL_ADDRESS,
        recipient=EMAIL_ADDRESS,
        subject="Failover Complete",
        body_text="Hello, the secondary system for the pilot light disaster recovery system has been spun up and application restored successfully."
    )

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
