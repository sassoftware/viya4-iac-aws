// Copyright © 2025, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package defaultplan

import (
	"github.com/stretchr/testify/assert"
	"test/helpers"
	"testing"
)

func TestPlanStorage(t *testing.T) {
	t.Parallel()

	tests := map[string]helpers.TestCase{
		"instanceTypeTest": {
			Expected:          "m6in.xlarge",
			ResourceMapName:   "module.nfs[0].aws_instance.vm",
			AttributeJsonPath: "{$.instance_type}",
		},
		"vmNotNilTest": {
			Expected:          "<nil>",
			ResourceMapName:   "module.nfs[0].aws_instance.vm",
			AttributeJsonPath: "{$}",
			AssertFunction:    assert.NotEqual,
		},
	}

	helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
}
