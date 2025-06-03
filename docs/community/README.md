
# Community-Contributed Features

Community-contributed features are submitted by community members to help expand the set of features that the project maintainers are capable of adding to the project on their own. 

## Community-Contributed Feature Expectations

As with new features, community contributed features should include unit tests which add to the level of community confidence in the feature and also help serve to indicate if any problems occur with the feature in future releases.

Community-features should be disabled by default. If applicable, a boolean configuration variable named community_enable_<community_feature> should be implemented for each community feature. The boolean variable should serve as a way to enable or disable the community feature. Additional community contributed feature configuration variables are also permitted, although if the feature is disabled, they should have no effect on the overall behavior of the project. Additional community contributed configuration variables should use the community_ prefix to indicate they are part of a community contributed feature.

## Submitting a Community-Contributed Feature

Submit a Community-Contributed Feature by creating a GitHub PR in this project. The PR should include the source code, unit tests and any required documentation including expected content for the docs/community/community-config-vars.md file

## What if a Community-Contributed Feature breaks

> [!CAUTION]
> Community members are responsible for maintaining these features. While project maintainers try to verify these features work as expected when merged, they cannot guarantee future releases will not break them. If you encounter issues while using these features, start a [GitHub Discussion](https://github.com/sassoftware/viya4-iac-aws/discussions) or open a Pull Request to fix them. As a last resort, you can create a GitHub Issue.

If a community-contributed feature is implemented as required, disabling the community feature should serve as a way to remove any impact that it has on the project. Community contributed features that affect the project when disabled should be re-worked to prevent that behavior.