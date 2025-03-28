// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package test

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	variables := getDefaultPlanVars(t)
	defaultTests := map[string]testCase{
		"resourceGroupName": {
			expected:          fmt.Sprintf("%s-rg", variables["prefix"]),
			resourceMapName:   "aws_resourcegroups_group.aws_rg",
			attributeJsonPath: "{$.name}",
		},
	}

	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range defaultTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestPlanDefaultDefaultNodepool(t *testing.T) {
	nodepoolTests := map[string]testCase{
		"defaultNodepoolVolumeType": {
			expected:          "gp2",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			attributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		},
		"defaultNodepoolVmType": {
			expected:          "[\"r6in.2xlarge\"]",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			attributeJsonPath: "{$.instance_types}",
		},
	}
	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range nodepoolTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestPlanDefaultEks(t *testing.T) {
	variables := getDefaultPlanVars(t)
	eksTests := map[string]testCase{
		"eksClusterName": {
			expected:          fmt.Sprintf("%s-eks", variables["prefix"]),
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.name}",
		},
		"clusterLogging": {
			expected:          "",
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.cluster_enabled_log_types}",
		},
	}

	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range eksTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}
