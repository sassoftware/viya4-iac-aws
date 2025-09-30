// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

// Test the default variables when using the sample-input-defaults.tfvars file
// with storage_type set to "ha" and storage_type_backend set to "efs".
// This should engage the EFS module, with the default values as tested herein.
func TestPlanEFS(t *testing.T) {
	t.Parallel()

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

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "efs"
	variables["storage_type_backend"] = "efs"
	variables["storage_type"] = "ha"

	helpers.RunTests(t, tests, helpers.GetPlan(t, variables))
}
