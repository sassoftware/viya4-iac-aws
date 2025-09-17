// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

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

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "netapp"
	variables["storage_type_backend"] = "ontap"
	variables["storage_type"] = "ha"

	helpers.RunTests(t, tests, helpers.GetPlan(t, variables))
}
