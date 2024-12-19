#!/usr/bin/env bash
set -e
spoke_account_id=$1
location=$2
export AWS_ACCESS_KEY_ID=$3
export AWS_SECRET_ACCESS_KEY=$4
export AWS_SESSION_TOKEN=$5

WAF_NAME="iac-awsng-${spoke_account_id}-acl"
RETRY_COUNT=3  # Number of retries
RETRY_DELAY=3  # Delay in seconds between retries
# Function to check the existence of WAF
check_waf() {
  local attempt=1
  while [ $attempt -le $RETRY_COUNT ]; do
    result=$(aws wafv2 list-web-acls --scope REGIONAL --region "$location" --query "WebACLs[?Name=='$WAF_NAME']" --output json)
    if [ $? -eq 0 ]; then
      arn=$(echo "$result" | jq -r '.[0].ARN // empty')
      if [ -n "$arn" ]; then
        echo "{\"exists\": \"true\", \"arn\": \"$arn\"}"
        exit 0
      else
        echo "{\"exists\": \"false\", \"arn\": \"\"}"
        exit 0
      fi
    else
      # echo "Attempt $attempt failed. Retrying in $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    fi
    attempt=$((attempt + 1))
  done
  # Final failure
  echo "{\"exists\": \"false\", \"arn\": \"\"}"
  exit 0
}
# Run the WAF check
check_waf


