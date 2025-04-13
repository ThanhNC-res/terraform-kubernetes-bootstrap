#!/bin/bash

# Usage:
# ./ec2-control.sh start i-01234 i-05678 i-09abc [region]
# ./ec2-control.sh stop i-01234 i-05678 i-09abc [region]

ACTION=$1
REGION=${@: -1}  # Assume last argument is region if it looks like a region
VALID_REGION_REGEX="^([a-z]{2}-[a-z]+-\d)$"
AWS_PROFILE="thanha3k51-profile"


# Remove first (action) and last (region) from list to get instance IDs
if [[ $REGION =~ $VALID_REGION_REGEX ]]; then
  INSTANCE_IDS=("${@:2:$#-2}")
else
  REGION="ap-southeast-1"
  INSTANCE_IDS=("${@:2}")
fi

if [[ -z "$ACTION" || ${#INSTANCE_IDS[@]} -eq 0 ]]; then
  echo "Usage: $0 <start|stop> <instance-id-1> <instance-id-2> ... [region]"
  exit 1
fi

case "$ACTION" in
  start)
    echo "Starting instances in region $REGION: ${INSTANCE_IDS[*]}"
    aws ec2 start-instances --instance-ids "${INSTANCE_IDS[@]}" --region "$REGION" --profile "$AWS_PROFILE"
    ;;
  stop)
    echo "Stopping instances in region $REGION: ${INSTANCE_IDS[*]}"
    aws ec2 stop-instances --instance-ids "${INSTANCE_IDS[@]}" --region "$REGION" --profile "$AWS_PROFILE"
    ;;
  *)
    echo "Invalid action: $ACTION. Use 'start' or 'stop'."
    exit 1
    ;;
esac
