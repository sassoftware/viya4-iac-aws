# Authenticating Terraform to Access AWS

In order to create and destroy AWS resources on your behalf, Terraform needs a AWS account that has sufficient permissions to perform all the actions defined in the Terraform manifest. You will need an AWS account IAM user that has at a minimum the permissions listed in [this policy](../../files/policies/devops-iac-eks-policy.json).

You can either use static credentials (including temporary credentials with session token) or a [profile with a credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

You can pass AWS credentials to Terraform by using either [AWS environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) or [TF_VAR_name](https://www.terraform.io/docs/cli/config/environment-variables.html#tf_var_name) environment variables. 

Follow these links for more information on how to create and retrieve AWS credentials to configure Terraform access to AWS:
- [Creating an IAM user in your AWS account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- [Using Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-profiles)

## Using AWS Static Credentials

You can pass values to Terraform variables with these **AWS environment variables**:

```bash
AWS_ACCESS_KEY_ID=<your_aws_access_key_id>
AWS_SECRET_ACCESS_KEY=<your_aws_secret_access_key>
AWS_SESSION_TOKEN=<your_aws_session_token>
```

or with these **TF_VAR_name environment variables**:

```bash
TF_VAR_aws_access_key_id=<your_aws_access_key_id>
TF_VAR_aws_secret_access_key=<your_aws_secret_access_key>
TF_VAR_aws_session_token=<your_aws_session_token>
```

> **NOTE** `AWS_SESSION_TOKEN` is optional and is only required when using you are using temporary AWS credentials. See the [AWS documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) on environment variables for more information.

## Using AWS Profile with Credentials File

You can pass values to Terraform variables with these **AWS environment variables**:

```bash
AWS_PROFILE=<your_aws_profile_name>
AWS_SHARED_CREDENTIALS_FILE=~/.aws/credentials
```

or with these **TF_VAR_name environment variables**:

```bash
TF_VAR_aws_profile=<your_aws_profile_name>
TF_VAR_aws_shared_credentials_file=~/.aws/credentials
```

You can find more information in the [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).
