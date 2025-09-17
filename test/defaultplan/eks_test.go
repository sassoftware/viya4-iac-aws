// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

func TestPlanEks(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)

	tests := map[string]helpers.TestCase{
		"eksClusterName": {
			Expected:          fmt.Sprintf("%s-eks", variables["prefix"]),
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.name}",
		},
		"clusterLogging": {
			Expected:          "",
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.cluster_enabled_log_types}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetPlanFromCache(t, variables))
}

// TestPlanConfig tests the general configuration settings for the EKS cluster
func TestPlanEKSConfig(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)

	tests := map[string]helpers.TestCase{
		// Kubernetes Configuration Tests
		"kubernetesVersion": {
			Expected:          "1.32",
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.version}",
			Message:           "Kubernetes version should match the specified version",
			AssertFunction:    assert.Equal,
		},
		"authenticationMode": {
			Expected:          "API_AND_CONFIG_MAP",
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.access_config[0].authentication_mode}",
			Message:           "Authentication mode should match the default value",
			AssertFunction:    assert.Equal,
		},
		"clusterApiMode": {
			Expected:          "true",
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.vpc_config[0].endpoint_public_access}",
			Message:           "Cluster API mode should be public by default",
			AssertFunction:    assert.Equal,
		},

		// Jump VM Configuration Tests
		"jumpVmEnabled": {
			Expected:          "true",
			ResourceMapName:   "module.jump[0].aws_instance.vm",
			AttributeJsonPath: "{$}",
			Message:           "Jump VM should be created by default",
			AssertFunction:    assert.NotEqual,
		},
		"jumpVmAdmin": {
			Expected:          "jump-admin",
			ResourceMapName:   "module.jump[0].aws_instance.vm",
			AttributeJsonPath: "{$.key_name}",
			Message:           "Jump VM admin key name should contain jump-admin",
			AssertFunction:    assert.Contains,
		},
		"jumpVmPublicIP": {
			Expected:          "<nil>",
			ResourceMapName:   "module.jump[0].aws_eip.eip[0]",
			AttributeJsonPath: "{$}",
			Message:           "Jump VM should have a public IP by default",
			AssertFunction:    assert.NotEqual,
		},
		"jumpRwxFilestorePath": {
			Expected:          "jump-vm",
			ResourceMapName:   "module.jump[0].aws_instance.vm",
			AttributeJsonPath: "{$.tags.Name}",
			Message:           "Jump VM should have the correct name tag",
			AssertFunction:    assert.Contains,
		},

		// Autoscaling Configuration Tests
		"autoscalingEnabled": {
			Expected:          "true",
			ResourceMapName:   "module.eks.module.eks_managed_node_group[\"default\"].aws_eks_node_group.this[0]",
			AttributeJsonPath: "{$.scaling_config[0].desired_size}",
			Message:           "Autoscaling should be enabled by default",
			AssertFunction:    assert.NotEqual,
		},

		// Tags Configuration Test
		"defaultProjectTag": {
			Expected:          "viya",
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.tags.project_name}",
			Message:           "Default project tag should be set to viya",
			AssertFunction:    assert.Equal,
		},
	}

	// Test admin access entry role ARNs if specified
	if adminRoleArns, ok := variables["admin_access_entry_role_arns"].([]interface{}); ok && len(adminRoleArns) > 0 {
		for i, arn := range adminRoleArns {
			tests[fmt.Sprintf("adminAccessEntryRoleArn_%d", i)] = helpers.TestCase{
				Expected:          arn.(string),
				ResourceMapName:   fmt.Sprintf("module.eks.aws_eks_access_entry.admin_access_entry[\"%s\"]", arn.(string)),
				AttributeJsonPath: "{$.principal_arn}",
				Message:           fmt.Sprintf("Admin access entry role ARN %d should be correctly configured", i),
				AssertFunction:    assert.Equal,
			}
		}
	}

	// Test static kubeconfig creation
	if createStaticKubeconfig, ok := variables["create_static_kubeconfig"].(bool); ok && createStaticKubeconfig {
		tests["staticKubeconfigServiceAccount"] = helpers.TestCase{
			Expected:          "<nil>",
			ResourceMapName:   "module.kubeconfig.kubernetes_service_account.kubernetes_sa[0]",
			AttributeJsonPath: "{$}",
			Message:           "Static kubeconfig service account should be created",
			AssertFunction:    assert.NotEqual,
		}
		tests["staticKubeconfigRoleBinding"] = helpers.TestCase{
			Expected:          "<nil>",
			ResourceMapName:   "module.kubeconfig.kubernetes_cluster_role_binding.kubernetes_crb[0]",
			AttributeJsonPath: "{$}",
			Message:           "Static kubeconfig role binding should be created",
			AssertFunction:    assert.NotEqual,
		}
	}

	helpers.RunTests(t, tests, helpers.GetPlanFromCache(t, variables))
}
