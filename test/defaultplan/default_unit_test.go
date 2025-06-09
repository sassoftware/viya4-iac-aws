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
