// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package test

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
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
		"k8sVersionTest": {
			expected:          "1.31",
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.version}",
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
func TestPlanGeneral(t *testing.T) {
	tests := map[string]testCase{
		"kubeconfigCrbResourceNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The kubeconfig CRB resource should exist",
		},
		"kubeconfigSAResourceNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The kubeconfig Service Account resource should exist",
		},
		"jumpVmNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.jump[0].aws_instance.vm",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The Jump VM resource should exist",
		},
		"jumpVmElasticIPNotNil": {
			expected:          "<nil>",
			resourceMapName:   "module.jump[0].aws_eip.eip[0]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
			message:           "The Jump VM Elastic IP resource should exist",
		},

		/*
			"jumpVmEnablePublicStaticIp": {
				expected:          "Static",
				resourceMapName:   "module.jump[0].aws_instance.vm",
				attributeJsonPath: "{$.allocation_method}",
				assertFunction:    assert.Equal,
				message:           "The Jump VM Public IP resource should have a Static allocation method",
			},
			"jumpVmAdmin": {
				expected:          "jumpuser",
				resourceMapName:   "module.jump[0].aws_instance.vm",
				attributeJsonPath: "{$.admin_username}",
				assertFunction:    assert.Equal,
				message:           "The Jump VM admin username should be jumpuser",
			},
			"jumpVmMachineType": {
				expected:          "Standard_B2s",
				resourceMapName:   "module.jump[0].aws_instance.vm",
				attributeJsonPath: "{$.size}",
				assertFunction:    assert.Equal,
				message:           "The Jump VM machine type should be Standard_B2s",
			},*/
	}
	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range tests {
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
		"defaultNodepoolOsDiskSize": {
			expected:          "200",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			attributeJsonPath: "{$.block_device_mappings[0].ebs[0].volume_size}",
		},
		"defaultNodepoolOsDiskIops": {
			expected:          "0",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			attributeJsonPath: "{$.block_device_mappings[0].ebs[0].iops}",
		},
		"defaultNodepoolNodeCount": {
			expected:          "1",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			attributeJsonPath: "{$.scaling_config[0].desired_size}",
		},
		"defaultNodepoolMaxNodes": {
			expected:          "5",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			attributeJsonPath: "{$.scaling_config[0].max_size}",
		},
		"defaultNodepoolMinNodes": {
			expected:          "1",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			attributeJsonPath: "{$.scaling_config[0].min_size}",
		},
		"defaultNodepoolMetadataHttpEndpoint": {
			expected:          "enabled",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			attributeJsonPath: "{$.metadata_options[0].http_endpoint}",
		},
		"defaultNodepoolMetadataHttpPutResponseHopLimit": {
			expected:          "1",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_launch_template.this[0]",
			attributeJsonPath: "{$.metadata_options[0].http_put_response_hop_limit}",
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

func TestPlanStorage(t *testing.T) {
	tests := map[string]testCase{
		"instanceTypeTest": {
			expected:          "m6in.xlarge",
			resourceMapName:   "module.nfs[0].aws_instance.vm",
			attributeJsonPath: "{$.instance_type}",
		},
		"vmNotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].aws_instance.vm",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range tests {
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

func TestPlanDefaultSecurityGroup(t *testing.T) {
	variables := getDefaultPlanVars(t)
	default_cidr := variables["default_public_access_cidrs"].([]string)[0]
	defaultTests := map[string]testCase{
		"securityGroupCIDR": {
			expected:          default_cidr,
			resourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", default_cidr),
			attributeJsonPath: "{$.cidr_ipv4}",
		},
		"securityGroupSSHIngressFromPort": {
			expected:          "22",
			resourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", default_cidr),
			attributeJsonPath: "{$.from_port}",
		},
		"securityGroupSSHIngressToPort": {
			expected:          "22",
			resourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", default_cidr),
			attributeJsonPath: "{$.to_port}",
		},
		"securityGroupIpProtocol": {
			expected:          "tcp",
			resourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", default_cidr),
			attributeJsonPath: "{$.ip_protocol}",
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

func TestPlanNetwork(t *testing.T) {
	tests := map[string]testCase{
		"vpcCidrTest": {
			expected:          "192.168.0.0/16",
			resourceMapName:   "module.vpc.aws_vpc.vpc[0]",
			attributeJsonPath: "{$.cidr_block}",
		},
		"subnetsTest": {
			expected:          "192.168.129.0/25",
			resourceMapName:   "module.vpc.aws_subnet.public[0]",
			attributeJsonPath: "{$.cidr_block}",
		},
		"subnetAzsTest": {
			expected:          "us-east-1a",
			resourceMapName:   "module.vpc.aws_subnet.public[0]",
			attributeJsonPath: "{$.availability_zone}",
		},
		// Use Existing
		/*
			"vnetSubnetTest": {
				expected:          "",
				resourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
				attributeJsonPath: "{$.subnet[0].name}",
			},
			"clusterEgressTypeTest": {
				expected:          "loadBalancer",
				resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				attributeJsonPath: "{$.network_profile[0].outbound_type}",
			},
			"networkPluginTest": {
				expected:          "kubenet",
				resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				attributeJsonPath: "{$.network_profile[0].network_plugin}",
			},
			"aksNetworkPolicyTest": {
				expected:          "",
				resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				attributeJsonPath: "{$.expressions.aks_network_policy.reference[0]}",
			},
			"aksNetworkPluginModeTest": {
				expected:          "",
				resourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				attributeJsonPath: "{$.expressions.aks_network_plugin_mode.reference[0]}",
			},*/
	}

	variables := getDefaultPlanVars(t)
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
// with storage_type set to "ha". This should engage the Azure NetApp Files module,
// with the default values as tested herein.
func TestPlanNetApp(t *testing.T) {
	tests := map[string]testCase{
		"deploymentType": {
			expected:          "SINGLE_AZ_1",
			resourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			attributeJsonPath: "{$.deployment_type}",
		},
		"storageCapacity": {
			expected:          "1024",
			resourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			attributeJsonPath: "{$.storage_capacity}",
		},
		"throughputCapacity": {
			expected:          "256",
			resourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			attributeJsonPath: "{$.throughput_capacity}",
		},
		"adminPassword": {
			expected:          "v3RyS3cretPa$sw0rd",
			resourceMapName:   "aws_fsx_ontap_file_system.ontap-fs[0]",
			attributeJsonPath: "{$.fsx_admin_password}",
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

func TestPlanNfs(t *testing.T) {
	tests := map[string]testCase{
		"create_nfs_public_IP": {
			expected:          "false",
			resourceMapName:   "module.nfs[0].aws_instance.vm",
			attributeJsonPath: "{$.associate_public_ip_address}",
		},
		// todo figure out how to test this variable
		/*
			"nfs_vm_admin": {
				expected:          "nfsuser",
				resourceMapName:   "module.nfs[0].aws_instance.vm",
				attributeJsonPath: "{$.vm_admin}",
			},*/
		"raidDisk0Iops": {
			expected:          "0",
			resourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[0]",
			attributeJsonPath: "{$.iops}",
		},
		"raidDisk0Type": {
			expected:          "gp2",
			resourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[0]",
			attributeJsonPath: "{$.type}",
		},
		"raidDisk0Size": {
			expected:          "128",
			resourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[0]",
			attributeJsonPath: "{$.size}",
		},
		"nfsDataDisk1NotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[1]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"nfsDataDisk2NotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[2]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
		"nfsDataDisk3NotNilTest": {
			expected:          "<nil>",
			resourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[3]",
			attributeJsonPath: "{$}",
			assertFunction:    assert.NotEqual,
		},
	}

	variables := getDefaultPlanVars(t)
	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

// TestPlanConfig tests the general configuration settings for the EKS cluster
func TestPlanConfig(t *testing.T) {
	variables := getDefaultPlanVars(t)

	configTests := map[string]testCase{
		// Kubernetes Configuration Tests
		"kubernetesVersion": {
			expected:          "1.31",
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.version}",
			message:          "Kubernetes version should match the specified version",
			assertFunction:   assert.Equal,
		},
		"authenticationMode": {
			expected:          "API_AND_CONFIG_MAP",
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.access_config[0].authentication_mode}",
			message:          "Authentication mode should match the default value",
			assertFunction:   assert.Equal,
		},
		"clusterApiMode": {
			expected:          "true",
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.vpc_config[0].endpoint_public_access}",
			message:          "Cluster API mode should be public by default",
			assertFunction:   assert.Equal,
		},

		// Jump VM Configuration Tests
		"jumpVmEnabled": {
			expected:          "true",
			resourceMapName:   "module.jump[0].aws_instance.vm",
			attributeJsonPath: "{$}",
			message:          "Jump VM should be created by default",
			assertFunction:   assert.NotEqual,
		},
		"jumpVmAdmin": {
			expected:          "jump-admin",
			resourceMapName:   "module.jump[0].aws_instance.vm",
			attributeJsonPath: "{$.key_name}",
			message:          "Jump VM admin key name should contain jump-admin",
			assertFunction:   assert.Contains,
		},
		"jumpVmPublicIP": {
			expected:          "<nil>",
			resourceMapName:   "module.jump[0].aws_eip.eip[0]",
			attributeJsonPath: "{$}",
			message:          "Jump VM should have a public IP by default",
			assertFunction:   assert.NotEqual,
		},
		"jumpRwxFilestorePath": {
			expected:          "jump-vm",
			resourceMapName:   "module.jump[0].aws_instance.vm",
			attributeJsonPath: "{$.tags.Name}",
			message:          "Jump VM should have the correct name tag",
			assertFunction:   assert.Contains,
		},

		// Autoscaling Configuration Tests
		"autoscalingEnabled": {
			expected:          "true",
			resourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			attributeJsonPath: "{$.scaling_config[0].desired_size}",
			message:          "Autoscaling should be enabled by default",
			assertFunction:   assert.NotEqual,
		},

		// Tags Configuration Test
		"defaultProjectTag": {
			expected:          "viya",
			resourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			attributeJsonPath: "{$.tags.project_name}",
			message:          "Default project tag should be set to viya",
			assertFunction:   assert.Equal,
		},
	}

	// Test admin access entry role ARNs if specified
	if admin_role_arns, ok := variables["admin_access_entry_role_arns"].([]interface{}); ok && len(admin_role_arns) > 0 {
		for i, arn := range admin_role_arns {
			configTests[fmt.Sprintf("adminAccessEntryRoleArn_%d", i)] = testCase{
				expected:          arn.(string),
				resourceMapName:   fmt.Sprintf("module.eks.aws_eks_access_entry.admin_access_entry[\"%s\"]", arn.(string)),
				attributeJsonPath: "{$.principal_arn}",
				message:          fmt.Sprintf("Admin access entry role ARN %d should be correctly configured", i),
				assertFunction:   assert.Equal,
			}
		}
	}

	// Test static kubeconfig creation
	if create_static_kubeconfig, ok := variables["create_static_kubeconfig"].(bool); ok && create_static_kubeconfig {
		configTests["staticKubeconfigServiceAccount"] = testCase{
			expected:          "<nil>",
			resourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			attributeJsonPath: "{$}",
			message:          "Static kubeconfig service account should be created",
			assertFunction:   assert.NotEqual,
		}
		configTests["staticKubeconfigRoleBinding"] = testCase{
			expected:          "<nil>",
			resourceMapName:   "module.kubeconfig.kubernetes_cluster_role_binding.kubernetes_crb[0]",
			attributeJsonPath: "{$}",
			message:          "Static kubeconfig role binding should be created",
			assertFunction:   assert.NotEqual,
		}
	}

	plan, err := initPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)

	for name, tc := range configTests {
		t.Run(name, func(t *testing.T) {
			runTest(t, tc, plan)
		})
	}
}

func TestPlanNetworking(t *testing.T) {
    tests := map[string]testCase{
        "vpcCidrTest": {
            expected:          "192.168.0.0/16",
            resourceMapName:   "module.vpc.aws_vpc.vpc[0]",
            attributeJsonPath: "{$.cidr_block}",
        },
        "subnetsTest": {
            expected:          "192.168.129.0/25",
            resourceMapName:   "module.vpc.aws_subnet.public[0]",
            attributeJsonPath: "{$.cidr_block}",
        },
        "subnetAzsTest": {
            expected:          "us-east-1a",
            resourceMapName:   "module.vpc.aws_subnet.public[0]",
            attributeJsonPath: "{$.availability_zone}",
        },
    }
        
    variables := getDefaultPlanVars(t)
    plan, err := initPlanWithVariables(t, variables)
    require.NotNil(t, plan)
    require.NoError(t, err)

    for name, tc := range tests {
        t.Run(name, func(t *testing.T) {
            runTest(t, tc, plan)
        })
    }
}