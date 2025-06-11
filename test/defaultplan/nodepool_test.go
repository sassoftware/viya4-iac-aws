// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

func TestPlanNodePool(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"defaultNodepoolVolumeType": {
			Expected:          "gp2",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		},
		"defaultNodepoolVmType": {
			Expected:          "[\"r6in.2xlarge\"]",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.instance_types}",
		},
		"defaultNodepoolOsDiskSize": {
			Expected:          "200",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_size}",
		},
		"defaultNodepoolOsDiskIops": {
			Expected:          "0",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].iops}",
		},
		"defaultNodepoolNodeCount": {
			Expected:          "1",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.scaling_config[0].desired_size}",
		},
		"defaultNodepoolMaxNodes": {
			Expected:          "5",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.scaling_config[0].max_size}",
		},
		"defaultNodepoolMinNodes": {
			Expected:          "1",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.scaling_config[0].min_size}",
		},
		"defaultNodepoolMetadataHttpEndpoint": {
			Expected:          "enabled",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.metadata_options[0].http_endpoint}",
		},
		"defaultNodepoolMetadataHttpPutResponseHopLimit": {
			Expected:          "1",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.metadata_options[0].http_put_response_hop_limit}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
