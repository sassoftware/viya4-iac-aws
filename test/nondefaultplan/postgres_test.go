// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

func TestPlanPostgreSQL(t *testing.T) {
	t.Parallel()

	defaultPostgresServerName := "default"
	postgresResourceMapName := "module.postgresql[\"" + defaultPostgresServerName + "\"].module.db_instance.aws_db_instance.this[0]"

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "postgres-servers"
	variables["postgres_servers"] = map[string]any{
		defaultPostgresServerName: map[string]any{},
	}

	tests := map[string]helpers.TestCase{
		"engineVersionTest": {
			Expected:          "15",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.engine_version}",
		},
		"instanceClassTest": {
			Expected:          "db.m6idn.xlarge",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.instance_class}",
		},
		"allocatedStorageTest": {
			Expected:          "128",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.allocated_storage}",
		},
		"backupRetentionTest": {
			Expected:          "7",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.backup_retention_period}",
		},
		"multiAZTest": {
			Expected:          "false",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.multi_az}",
		},
		"deletionProtectionTest": {
			Expected:          "false",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.deletion_protection}",
		},
		"storageEncryptedTest": {
			Expected:          "false",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.storage_encrypted}",
		},
		"administratorlogin": {
			Expected:          "pgadmin",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.username}",
		},
		"administrator_password": {
			Expected:          "my$up3rS3cretPassw0rd",
			ResourceMapName:   postgresResourceMapName,
			AttributeJsonPath: "{$.password}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetPlan(t, variables))
}
