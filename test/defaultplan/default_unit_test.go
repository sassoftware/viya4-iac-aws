// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"fmt"
	"test/helpers"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Test the default variables when using the sample-input-defaults.tfvars file.
// Verify that the tfplan is using the default variables from the CONFIG-VARS
func TestPlanDefaults(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)

	tests := map[string]helpers.TestCase{
		"resourceGroupName": {
			Expected:          fmt.Sprintf("%s-rg", variables["prefix"]),
			ResourceMapName:   "aws_resourcegroups_group.aws_rg",
			AttributeJsonPath: "{$.name}",
		},
		"k8sVersionTest": {
			Expected:          "1.31",
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.version}",
		},
		"kubeconfigCrbResourceNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The kubeconfig CRB resource should exist",
		},
		"kubeconfigSAResourceNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The kubeconfig Service Account resource should exist",
		},
		"jumpVmNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.jump[0].aws_instance.vm",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The Jump VM resource should exist",
		},
		"jumpVmElasticIPNotNil": {
			Expected:          "<nil>",
			ResourceMapName:   "module.jump[0].aws_eip.eip[0]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
			Message:           "The Jump VM Elastic IP resource should exist",
		},

		/*
			"jumpVmEnablePublicStaticIp": {
				Expected:          "Static",
				ResourceMapName:   "module.jump[0].aws_instance.vm",
				AttributeJsonPath: "{$.allocation_method}",
				AssertFunction:    assert.Equal,
				Message:           "The Jump VM Public IP resource should have a Static allocation method",
			},
			"jumpVmAdmin": {
				Expected:          "jumpuser",
				ResourceMapName:   "module.jump[0].aws_instance.vm",
				AttributeJsonPath: "{$.admin_username}",
				AssertFunction:    assert.Equal,
				Message:           "The Jump VM admin username should be jumpuser",
			},
			"jumpVmMachineType": {
				Expected:          "Standard_B2s",
				ResourceMapName:   "module.jump[0].aws_instance.vm",
				AttributeJsonPath: "{$.size}",
				AssertFunction:    assert.Equal,
				Message:           "The Jump VM machine type should be Standard_B2s",
			},*/
	}

	helpers.RunTests(t, tests, helpers.GetPlanFromCache(t, variables))
}

func TestPlanNetwork(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"vpcCidrTest": {
			Expected:          "192.168.0.0/16",
			ResourceMapName:   "module.vpc.aws_vpc.vpc[0]",
			AttributeJsonPath: "{$.cidr_block}",
		},
		"subnetsTest": {
			Expected:          "192.168.129.0/25",
			ResourceMapName:   "module.vpc.aws_subnet.public[0]",
			AttributeJsonPath: "{$.cidr_block}",
		},
		"subnetAzsTest": {
			Expected:          "us-east-1a",
			ResourceMapName:   "module.vpc.aws_subnet.public[0]",
			AttributeJsonPath: "{$.availability_zone}",
		},
		// Use Existing
		/*
			"vnetSubnetTest": {
				Expected:          "",
				ResourceMapName:   "module.vnet.azurerm_virtual_network.vnet[0]",
				AttributeJsonPath: "{$.subnet[0].name}",
			},
			"clusterEgressTypeTest": {
				Expected:          "loadBalancer",
				ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				AttributeJsonPath: "{$.network_profile[0].outbound_type}",
			},
			"networkPluginTest": {
				Expected:          "kubenet",
				ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				AttributeJsonPath: "{$.network_profile[0].network_plugin}",
			},
			"aksNetworkPolicyTest": {
				Expected:          "",
				ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				AttributeJsonPath: "{$.expressions.aks_network_policy.reference[0]}",
			},
			"aksNetworkPluginModeTest": {
				Expected:          "",
				ResourceMapName:   "module.aks.azurerm_kubernetes_cluster.aks",
				AttributeJsonPath: "{$.expressions.aks_network_plugin_mode.reference[0]}",
			},*/
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
