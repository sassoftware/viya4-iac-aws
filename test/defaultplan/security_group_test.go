// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"fmt"
	"test/helpers"
	"testing"
)

func TestPlanSecurityGroup(t *testing.T) {
	t.Parallel()

	variables := helpers.GetDefaultPlanVars(t)
	defaultCidr := variables["default_public_access_cidrs"].([]string)[0]

	tests := map[string]helpers.TestCase{
		"securityGroupCIDR": {
			Expected:          defaultCidr,
			ResourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", defaultCidr),
			AttributeJsonPath: "{$.cidr_ipv4}",
		},
		"securityGroupSSHIngressFromPort": {
			Expected:          "22",
			ResourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", defaultCidr),
			AttributeJsonPath: "{$.from_port}",
		},
		"securityGroupSSHIngressToPort": {
			Expected:          "22",
			ResourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", defaultCidr),
			AttributeJsonPath: "{$.to_port}",
		},
		"securityGroupIpProtocol": {
			Expected:          "tcp",
			ResourceMapName:   fmt.Sprintf("aws_vpc_security_group_ingress_rule.vms[\"%s\"]", defaultCidr),
			AttributeJsonPath: "{$.ip_protocol}",
		},
	}

	helpers.RunTests(t, tests, helpers.GetPlanFromCache(t, variables))
}
