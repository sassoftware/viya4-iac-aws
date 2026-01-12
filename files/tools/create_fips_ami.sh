#!/usr/bin/env bash

# Copyright © 2026, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

##
# Script to create a custom FIPS-enabled Amazon Linux 2023 AMI for EKS
#
# Usage:
#   ./create_fips_ami.sh <region> <ssm-parameter-path>
#
# Example:
#   ./create_fips_ami.sh us-east-1 /viya4/fips/al2023-ami-id
##

set -e

REGION="${1:-us-east-1}"
SSM_PARAMETER="${2:-/viya4/fips/al2023-ami-id}"
INSTANCE_TYPE="t3.medium"
AMI_NAME="AL2023-FIPS-EKS-$(date +%Y%m%d-%H%M%S)"

echo "========================================="
echo "Creating FIPS-enabled AL2023 AMI"
echo "========================================="
echo "Region: $REGION"
echo "AMI Name: $AMI_NAME"
echo "SSM Parameter: $SSM_PARAMETER"
echo ""

# Get the latest AL2023 AMI ID
echo "Looking up latest AL2023 AMI..."
AL2023_AMI=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023.*-kernel-*-x86_64" \
            "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)

if [ -z "$AL2023_AMI" ] || [ "$AL2023_AMI" == "None" ]; then
  echo "ERROR: Could not find AL2023 AMI in region $REGION"
  exit 1
fi

echo "Found AL2023 AMI: $AL2023_AMI"
echo ""

# Create temporary key pair
KEY_NAME="fips-ami-temp-$(date +%s)"
echo "Creating temporary key pair: $KEY_NAME"
aws ec2 create-key-pair \
  --region "$REGION" \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "/tmp/${KEY_NAME}.pem"
chmod 400 "/tmp/${KEY_NAME}.pem"

# Create security group for SSH access
SG_NAME="fips-ami-temp-sg-$(date +%s)"
echo "Creating temporary security group: $SG_NAME"
VPC_ID=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=is-default,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text)

SG_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name "$SG_NAME" \
  --description "Temporary SG for FIPS AMI creation" \
  --vpc-id "$VPC_ID" \
  --output text)

aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

echo "Security Group: $SG_ID"
echo ""

# Launch instance
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AL2023_AMI" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=fips-ami-builder}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

# Get instance public IP
INSTANCE_IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instance IP: $INSTANCE_IP"
echo "Waiting 30 seconds for SSH to be ready..."
sleep 30

# Enable FIPS on the instance
echo ""
echo "Enabling FIPS mode on instance..."
ssh -o StrictHostKeyChecking=no -i "/tmp/${KEY_NAME}.pem" "ec2-user@${INSTANCE_IP}" << 'ENDSSH'
  set -e
  echo "Running fips-mode-setup..."
  sudo fips-mode-setup --enable
  echo "FIPS setup complete. Rebooting..."
  sudo reboot
ENDSSH

echo "Instance is rebooting..."
sleep 10

# Wait for instance to come back up
echo "Waiting for instance to be running after reboot..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"
echo "Waiting 30 seconds for SSH to be ready..."
sleep 30

# Verify FIPS is enabled
echo ""
echo "Verifying FIPS mode is enabled..."
FIPS_STATUS=$(ssh -o StrictHostKeyChecking=no -i "/tmp/${KEY_NAME}.pem" "ec2-user@${INSTANCE_IP}" \
  "cat /proc/sys/crypto/fips_enabled")

if [ "$FIPS_STATUS" != "1" ]; then
  echo "ERROR: FIPS mode not enabled (status: $FIPS_STATUS)"
  echo "Cleaning up..."
  aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID"
  exit 1
fi

echo "✓ FIPS mode verified enabled"
echo ""

# Stop instance before creating AMI
echo "Stopping instance..."
aws ec2 stop-instances --region "$REGION" --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-stopped --region "$REGION" --instance-ids "$INSTANCE_ID"

# Create AMI
echo "Creating AMI: $AMI_NAME"
FIPS_AMI_ID=$(aws ec2 create-image \
  --region "$REGION" \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --description "Amazon Linux 2023 with FIPS 140-2 enabled for EKS" \
  --tag-specifications "ResourceType=image,Tags=[{Key=Name,Value=${AMI_NAME}},{Key=FIPS,Value=enabled}]" \
  --query 'ImageId' \
  --output text)

echo "AMI ID: $FIPS_AMI_ID"
echo "Waiting for AMI to be available..."
aws ec2 wait image-available --region "$REGION" --image-ids "$FIPS_AMI_ID"

# Store in SSM Parameter Store
echo ""
echo "Storing AMI ID in SSM Parameter Store..."
aws ssm put-parameter \
  --region "$REGION" \
  --name "$SSM_PARAMETER" \
  --value "$FIPS_AMI_ID" \
  --type "String" \
  --description "Custom FIPS-enabled AL2023 AMI for EKS nodes (created $(date))" \
  --overwrite

echo "✓ AMI ID stored in SSM: $SSM_PARAMETER"
echo ""

# Cleanup
echo "Cleaning up temporary resources..."
aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" >/dev/null 2>&1 || true
aws ec2 delete-security-group --region "$REGION" --group-id "$SG_ID" >/dev/null 2>&1 || true
aws ec2 delete-key-pair --region "$REGION" --key-name "$KEY_NAME" >/dev/null 2>&1 || true
rm -f "/tmp/${KEY_NAME}.pem"

echo ""
echo "========================================="
echo "✓ FIPS AMI Creation Complete!"
echo "========================================="
echo "AMI ID: $FIPS_AMI_ID"
echo "Region: $REGION"
echo "SSM Parameter: $SSM_PARAMETER"
echo ""
echo "You can now use this in your terraform variables:"
echo "  fips_enabled           = true"
echo "  fips_ami_ssm_parameter = \"$SSM_PARAMETER\""
echo ""
