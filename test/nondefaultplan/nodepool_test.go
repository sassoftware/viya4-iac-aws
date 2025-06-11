// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

// Test the default nodepool when using the sample-input-defaults.tfvars file
// and overriding the default_nodepool_os_disk_type to gp3.
func TestPlanNodepoolGp3(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"nodepoolVolumeTypeGp3": {
			Expected:          "gp3",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		},
	}

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "nodepoolgp3"
	variables["default_nodepool_os_disk_type"] = "gp3"

	helpers.RunTests(t, tests, helpers.GetPlan(t, variables))
}

// Test the default nodepool when using the sample-input-defaults.tfvars file
// and overriding the default_nodepool_os_disk_type to io1.
func TestPlanNodepoolIo1(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"defaultNodepoolVolumeTypeIo1": {
			Expected:          "io1",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		},
	}

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "nodepoolio1"
	variables["default_nodepool_os_disk_type"] = "io1"

	helpers.RunTests(t, tests, helpers.GetPlan(t, variables))
}

func TestPlanNodePools(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"gpuNodePoolVmType": {
			Expected:          "g4dn.xlarge",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.instance_types[0]}",
			Message:           "GPU node pool should have correct instance type",
			AssertFunction:    assert.Equal,
		},
		"gpuNodePoolCpuType": {
			Expected:          "AL2_x86_64_GPU",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.ami_type}",
			Message:           "GPU node pool should have correct CPU type",
			AssertFunction:    assert.Equal,
		},
		"gpuNodePoolDiskType": {
			Expected:          "gp2",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
			Message:           "GPU node pool should have correct disk type",
			AssertFunction:    assert.Equal,
		},
		"gpuNodePoolDiskSize": {
			Expected:          "100",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_size}",
			Message:           "GPU node pool should have correct disk size",
			AssertFunction:    assert.Equal,
		},
		"gpuNodePoolScaling": {
			Expected:          "1",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.scaling_config[0].min_size}",
			Message:           "GPU node pool should have correct minimum nodes",
			AssertFunction:    assert.Equal,
		},
		"highMemoryNodePoolVmType": {
			Expected:          "r5.2xlarge",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"high-memory\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.instance_types[0]}",
			Message:           "High-memory node pool should have correct instance type",
			AssertFunction:    assert.Equal,
		},
		"highMemoryNodePoolDiskType": {
			Expected:          "io1",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"high-memory\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
			Message:           "High-memory node pool should have correct disk type",
			AssertFunction:    assert.Equal,
		},
		"highMemoryNodePoolDiskIops": {
			Expected:          "3000",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"high-memory\"].aws_launch_template.this[0]",
			AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].iops}",
			Message:           "High-memory node pool should have correct disk IOPS",
			AssertFunction:    assert.Equal,
		},
	}

	for _, pool := range []string{"gpu", "high-memory"} {
		tests[fmt.Sprintf("%sNodePoolMetadataEndpoint", pool)] = helpers.TestCase{
			Expected:          "enabled",
			ResourceMapName:   fmt.Sprintf("module.eks.module.eks_managed_node_group[\"%s\"].aws_launch_template.this[0]", pool),
			AttributeJsonPath: "{$.metadata_options[0].http_endpoint}",
			Message:           fmt.Sprintf("%s node pool should have correct metadata endpoint", pool),
			AssertFunction:    assert.Equal,
		}

		tests[fmt.Sprintf("%sNodePoolMetadataTokens", pool)] = helpers.TestCase{
			Expected:          "required",
			ResourceMapName:   fmt.Sprintf("module.eks.module.eks_managed_node_group[\"%s\"].aws_launch_template.this[0]", pool),
			AttributeJsonPath: "{$.metadata_options[0].http_tokens}",
			Message:           fmt.Sprintf("%s node pool should have correct metadata tokens", pool),
			AssertFunction:    assert.Equal,
		}

		tests[fmt.Sprintf("%sNodePoolMetadataHopLimit", pool)] = helpers.TestCase{
			Expected:          "1",
			ResourceMapName:   fmt.Sprintf("module.eks.module.eks_managed_node_group[\"%s\"].aws_launch_template.this[0]", pool),
			AttributeJsonPath: "{$.metadata_options[0].http_put_response_hop_limit}",
			Message:           fmt.Sprintf("%s node pool should have correct metadata hop limit", pool),
			AssertFunction:    assert.Equal,
		}
	}

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "nodepool"

	if _, ok := variables["node_pools"]; !ok {
		variables["node_pools"] = map[string]map[string]interface{}{
			"gpu": {
				"vm_type":                              "g4dn.xlarge",
				"cpu_type":                             "AL2_x86_64_GPU",
				"os_disk_type":                         "gp2",
				"os_disk_size":                         100,
				"os_disk_iops":                         3000,
				"min_nodes":                            1,
				"max_nodes":                            3,
				"node_taints":                          []string{"nvidia.com/gpu=present:NoSchedule"},
				"node_labels":                          map[string]string{"workload.sas.com/node": ""},
				"metadata_http_endpoint":               "enabled",
				"metadata_http_tokens":                 "required",
				"metadata_http_put_response_hop_limit": 1,
				"custom_data":                          "",
			},
			"high-memory": {
				"vm_type":                              "r5.2xlarge",
				"cpu_type":                             "AL2_x86_64",
				"os_disk_type":                         "io1",
				"os_disk_size":                         200,
				"os_disk_iops":                         3000,
				"min_nodes":                            2,
				"max_nodes":                            4,
				"node_taints":                          []string{"workload.sas.com/memory=high:NoSchedule"},
				"node_labels":                          map[string]string{"workload.sas.com/node": ""},
				"metadata_http_endpoint":               "enabled",
				"metadata_http_tokens":                 "required",
				"metadata_http_put_response_hop_limit": 1,
				"custom_data":                          "",
			},
		}
	}

	helpers.RunTests(t, tests, helpers.GetPlan(t, variables))
}
