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
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
