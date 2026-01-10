#!/bin/bash
# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Script to validate FIPS mode is enabled on EKS nodes
# Usage: ./validate_fips.sh

set -e

echo "==========================================="
echo "FIPS 140-2 Validation for EKS Nodes"
echo "==========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed or not in PATH"
    exit 1
fi

# Get list of nodes
echo "Fetching node list..."
NODES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

if [ -z "$NODES" ]; then
    echo "ERROR: No nodes found in cluster"
    exit 1
fi

echo "Found nodes: $NODES"
echo ""

# Check FIPS status on each node
FAILED_NODES=""
SUCCESS_COUNT=0
TOTAL_COUNT=0

for NODE in $NODES; do
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    echo "Checking FIPS status on node: $NODE"
    
    # Try to get a pod running on this node from kube-system namespace
    POD=$(kubectl get pods -n kube-system -o wide --field-selector spec.nodeName=$NODE --no-headers 2>/dev/null | head -n 1 | awk '{print $1}')
    
    if [ -z "$POD" ]; then
        echo "  ⚠️  WARNING: No pod found on node $NODE to check FIPS status"
        continue
    fi
    
    echo "  Using pod: $POD"
    
    # Check FIPS mode
    FIPS_STATUS=$(kubectl exec -it $POD -n kube-system -- cat /proc/sys/crypto/fips_enabled 2>/dev/null | tr -d '\r')
    
    if [ "$FIPS_STATUS" = "1" ]; then
        echo "  ✅ FIPS mode is ENABLED (status: $FIPS_STATUS)"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ❌ FIPS mode is DISABLED (status: $FIPS_STATUS)"
        FAILED_NODES="$FAILED_NODES $NODE"
    fi
    echo ""
done

# Summary
echo "==========================================="
echo "FIPS Validation Summary"
echo "==========================================="
echo "Total nodes checked: $TOTAL_COUNT"
echo "Nodes with FIPS enabled: $SUCCESS_COUNT"
echo "Nodes with FIPS disabled: $((TOTAL_COUNT - SUCCESS_COUNT))"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo ""
    echo "✅ SUCCESS: FIPS is enabled on all nodes"
    exit 0
else
    echo ""
    echo "❌ FAILURE: FIPS is not enabled on the following nodes:$FAILED_NODES"
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check node user data configuration"
    echo "2. Verify fips_enabled variable is set to true"
    echo "3. Check node system logs: kubectl logs -n kube-system <pod-name>"
    echo "4. SSH to node and run: fips-mode-setup --check"
    exit 1
fi
