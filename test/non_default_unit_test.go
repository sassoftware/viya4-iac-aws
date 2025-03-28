// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package test

import (
	"testing"

	"github.com/stretchr/testify/require"
)

// Test the default nodepool when using the sample-input-defaults.tfvars file
// and overriding the default_nodepool_os_disk_type to gp3.
func TestPlanNonDefaultDefaultNodepoolgp3(t *testing.T) {
	nodepoolTests := map[string]testCase{
		"defaultNodepoolVolumeTypeGp3": {
			expected:          "gp3",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			attributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		},
	}
	variables := getDefaultPlanVars(t)
	variables["default_nodepool_os_disk_type"] = "gp3"
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range nodepoolTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Test the default nodepool when using the sample-input-defaults.tfvars file
// and overriding the default_nodepool_os_disk_type to io1.
func TestPlanNonDefaultDefaultNodepoolio1(t *testing.T) {
	nodepoolTests := map[string]testCase{
		"defaultNodepoolVolumeTypeIo1": {
			expected:          "io1",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			attributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		},
	}
	variables := getDefaultPlanVars(t)
	variables["default_nodepool_os_disk_type"] = "io1"
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range nodepoolTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestPlanNonDefaultEks(t *testing.T) {
	variables := getDefaultPlanVars(t)
	variables["cluster_enabled_log_types"] = []string{"api", "audit", "authenticator"}
	eksTests := map[string]testCase{
		"clusterLogging": {
			expected:          "[\"api\",\"audit\",\"authenticator\"]",
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.enabled_cluster_log_types}",
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
