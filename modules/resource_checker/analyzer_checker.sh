#!/usr/bin/env bash
set -e
location=$1
ANALYZER_NAME="sas-awsng-accessanalyzer-ext-$location"
export AWS_ACCESS_KEY_ID=$2
export AWS_SECRET_ACCESS_KEY=$3
export AWS_SESSION_TOKEN=$4

RETRY_COUNT=3  # Number of retries
RETRY_DELAY=3  # Delay in seconds between retries
# Function to check the existence of WAF
check_analyzer() {
  local attempt=1
  while [ $attempt -le $RETRY_COUNT ]; do
    result=$(aws accessanalyzer list-analyzers --region $location --query "analyzers[?name=='$ANALYZER_NAME']" --output json )
    if [ $? -eq 0 ]; then
      arn=$(echo "$result" | jq -r '.[0].arn // empty')
      if [ -n "$arn" ]; then
        echo "{\"exists\": \"true\", \"arn\": \"$arn\"}"
        exit 0
      # else
      #   echo "{\"exists\": \"false\", \"arn\": \"\"}"
      #   exit 0
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
check_analyzer


