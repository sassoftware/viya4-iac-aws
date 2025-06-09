// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"fmt"
	"test/helpers"
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

// Test the default variables when using the sample-input-defaults.tfvars file
// with storage_type set to "ha". This should engage the Azure NetApp Files module,
// with the default values as tested herein.
func TestPlanNetApp(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"deploymentType": {
			Expected:          "SINGLE_AZ_1",
			ResourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			AttributeJsonPath: "{$.deployment_type}",
		},
		"storageCapacity": {
			Expected:          "1024",
			ResourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			AttributeJsonPath: "{$.storage_capacity}",
		},
		"throughputCapacity": {
			Expected:          "256",
			ResourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			AttributeJsonPath: "{$.throughput_capacity}",
		},
		"adminPassword": {
			Expected:          "v3RyS3cretPa$sw0rd",
			ResourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			AttributeJsonPath: "{$.fsx_admin_password}",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["storage_type_backend"] = "ontap"
	variables["storage_type"] = "ha"
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// Test the default variables when using the sample-input-defaults.tfvars file
// with storage_type set to "ha" and storage_type_backend set to "efs".
// This should engage the EFS module, with the default values as tested herein.
func TestPlanEFS(t *testing.T) {
	tests := map[string]helpers.TestCase{
		"efs_performance_mode": {
			Expected:          "generalPurpose",
			ResourceMapName:   "aws_efs_file_system.efs-fs[0]",
			AttributeJsonPath: "{$.performance_mode}",
		},
		"enable_efs_encryption": {
			Expected:          "false",
			ResourceMapName:   "aws_efs_file_system.efs-fs[0]",
			AttributeJsonPath: "{$.encrypted}",
		},
		"efs_throughput_mode": {
			Expected:          "bursting",
			ResourceMapName:   "aws_efs_file_system.efs-fs[0]",
			AttributeJsonPath: "{$.throughput_mode}",
		},
	}

	variables := getDefaultPlanVars(t)
	variables["storage_type_backend"] = "efs"
	variables["storage_type"] = "ha"

	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range tests {
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

func TestPlanNodePools(t *testing.T) {
	variables := helpers.GetDefaultPlanVars(t)

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

	tests := map[string]helpers.TestCase{}

	tests["gpuNodePoolVmType"] = helpers.TestCase{
		Expected:          "g4dn.xlarge",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_eks_node_group.this[0]",
		AttributeJsonPath: "{$.instance_types[0]}",
		Message:           "GPU node pool should have correct instance type",
		AssertFunction:    assert.Equal,
	}

	tests["gpuNodePoolCpuType"] = helpers.TestCase{
		Expected:          "AL2_x86_64_GPU",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_eks_node_group.this[0]",
		AttributeJsonPath: "{$.ami_type}",
		Message:           "GPU node pool should have correct CPU type",
		AssertFunction:    assert.Equal,
	}

	tests["gpuNodePoolDiskType"] = helpers.TestCase{
		Expected:          "gp2",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_launch_template.this[0]",
		AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		Message:           "GPU node pool should have correct disk type",
		AssertFunction:    assert.Equal,
	}

	tests["gpuNodePoolDiskSize"] = helpers.TestCase{
		Expected:          "100",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_launch_template.this[0]",
		AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_size}",
		Message:           "GPU node pool should have correct disk size",
		AssertFunction:    assert.Equal,
	}

	tests["gpuNodePoolScaling"] = helpers.TestCase{
		Expected:          "1",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"gpu\"].aws_eks_node_group.this[0]",
		AttributeJsonPath: "{$.scaling_config[0].min_size}",
		Message:           "GPU node pool should have correct minimum nodes",
		AssertFunction:    assert.Equal,
	}

	tests["highMemoryNodePoolVmType"] = helpers.TestCase{
		Expected:          "r5.2xlarge",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"high-memory\"].aws_eks_node_group.this[0]",
		AttributeJsonPath: "{$.instance_types[0]}",
		Message:           "High-memory node pool should have correct instance type",
		AssertFunction:    assert.Equal,
	}

	tests["highMemoryNodePoolDiskType"] = helpers.TestCase{
		Expected:          "io1",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"high-memory\"].aws_launch_template.this[0]",
		AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_type}",
		Message:           "High-memory node pool should have correct disk type",
		AssertFunction:    assert.Equal,
	}

	tests["highMemoryNodePoolDiskIops"] = helpers.TestCase{
		Expected:          "3000",
		ResourceMapName:   "module.eks.module.eks_managed_node_group[\"high-memory\"].aws_launch_template.this[0]",
		AttributeJsonPath: "{$.block_device_mappings[0].ebs[0].iops}",
		Message:           "High-memory node pool should have correct disk IOPS",
		AssertFunction:    assert.Equal,
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

	helpers.RunTests(t, tests, helpers.GetPlanFr(t))
}
