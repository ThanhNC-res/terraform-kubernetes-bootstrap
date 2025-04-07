#!/bin/bash

# Usage:
# ./start_stop_instance.sh start i-0123456789abcdef
# ./start_stop_instance.sh stop i-0123456789abcdef

ACTION=$1
INSTANCE_ID=$2
REGION=${3:-ap-southeast-1}  # Default to us-east-1 if not provided

if [[ -z "$ACTION" || -z "$INSTANCE_ID" ]]; then
  echo "Usage: $0 <start|stop> <instance-id> [region]"
  exit 1
fi

if [[ "$ACTION" == "start" ]]; then
  echo "Starting EC2 instance: $INSTANCE_ID in $REGION..."
  aws ec2 start-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --profile "thanha3k51-profile"
elif [[ "$ACTION" == "stop" ]]; then
  echo "Stopping EC2 instance: $INSTANCE_ID in $REGION..."
  aws ec2 stop-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --profile "thanha3k51-profile"
else
  echo "Invalid action: $ACTION. Use 'start' or 'stop'."
  exit 1
fi