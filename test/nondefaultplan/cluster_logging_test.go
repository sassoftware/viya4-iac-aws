// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package nondefaultplan

import (
	"test/helpers"
	"testing"
)

func TestPlanEks(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"clusterLogging": {
			Expected:          "[\"api\",\"audit\",\"authenticator\"]",
			ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
			AttributeJsonPath: "{$.enabled_cluster_log_types}",
		},
	}

	variables := helpers.GetDefaultPlanVars(t)
	variables["prefix"] = "clusterlogging"
	variables["cluster_enabled_log_types"] = []string{"api", "audit", "authenticator"}

	helpers.RunTests(t, tests, helpers.GetPlan(t, variables))
}
