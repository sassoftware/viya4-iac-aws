// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

func TestPlanNetworking(t *testing.T) {
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
