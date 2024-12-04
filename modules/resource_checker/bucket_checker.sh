#!/usr/bin/env bash
set -e
spoke_account_id=$1
location=$2
export AWS_ACCESS_KEY_ID=$3
export AWS_SECRET_ACCESS_KEY=$4
export AWS_SESSION_TOKEN=$5
BUCKET_NAME="aws-waf-logs-infra-${spoke_account_id}-${location}-bkt"
RETRY_COUNT=3  # Number of retries
RETRY_DELAY=3  # Delay in seconds between retries
# Function to check the existence of the S3 bucket
check_bucket() {
  local attempt=1
  while [ $attempt -le $RETRY_COUNT ]; do
    result=$(aws  s3api list-buckets --region "$location" --query "Buckets[?Name=='$BUCKET_NAME']" --output json)

    if [ $? -eq 0 ]; then
      # Check if the bucket exists by examining the output
      if [ "$(echo "$result" | jq 'length')" -gt 0 ]; then
        echo "{\"exists\": \"true\"}"
        exit 0
      else
        echo "{\"exists\": \"false\"}"
        exit 0
      fi
    else
      # If the command fails, wait and retry
      sleep $RETRY_DELAY
    fi
    attempt=$((attempt + 1))
  done
  # Final failure case
  echo "{\"exists\": \"false\"}"
  exit 1
}

# Run the S3 bucket check
check_bucket