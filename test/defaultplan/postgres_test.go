// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"test/helpers"
	"testing"
)

func TestPlanPostgreSQL(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"engineVersionTest": {
			Expected:          "15",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.engine_version}",
		},
		"instanceClassTest": {
			Expected:          "db.m6idn.xlarge",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.instance_class}",
		},
		"allocatedStorageTest": {
			Expected:          "128",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.allocated_storage}",
		},
		"backupRetentionTest": {
			Expected:          "7",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.backup_retention_period}",
		},
		"multiAZTest": {
			Expected:          "false",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.multi_az}",
		},
		"deletionProtectionTest": {
			Expected:          "false",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.deletion_protection}",
		},
		"storageEncryptedTest": {
			Expected:          "false",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.storage_encrypted}",
		},
		"administratorlogin": {
			Expected:          "pgadmin",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.username}",
		},
		"administrator_password": {
			Expected:          "my$up3rS3cretPassw0rd",
			ResourceMapName:   "module.postgresql[\"default\"].module.db_instance.aws_db_instance.this[0]",
			AttributeJsonPath: "{$.password}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
