// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

func TestPlanNfs(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"create_nfs_public_IP": {
			Expected:          "false",
			ResourceMapName:   "module.nfs[0].aws_instance.vm",
			AttributeJsonPath: "{$.associate_public_ip_address}",
		},
		// todo figure out how to test this variable
		/*
			"nfs_vm_admin": {
				Expected:          "nfsuser",
				ResourceMapName:   "module.nfs[0].aws_instance.vm",
				AttributeJsonPath: "{$.vm_admin}",
			},*/
		"raidDisk0Iops": {
			Expected:          "0",
			ResourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[0]",
			AttributeJsonPath: "{$.iops}",
		},
		"raidDisk0Type": {
			Expected:          "gp2",
			ResourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[0]",
			AttributeJsonPath: "{$.type}",
		},
		"raidDisk0Size": {
			Expected:          "128",
			ResourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[0]",
			AttributeJsonPath: "{$.size}",
		},
		"nfsDataDisk1NotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[1]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"nfsDataDisk2NotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[2]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
		"nfsDataDisk3NotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].aws_ebs_volume.raid_disk[3]",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
