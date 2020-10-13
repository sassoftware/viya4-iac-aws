### Authenticating Terraform to access AWS

Terraform creates and destroys resources in AWS on your behalf. In order to do so, it needs to authenticate itself to AWS with the appropriate permissions.

You will need an identity that has at a mininum the permissions listed in [this policy](../../files/devops-iac-eks-policy.json).

You can use either static credentials (including temporary credentials with session token), or an AWS Profile.

You can pass the credentials into the Terraform AWS provider either by Terraform variables, or as AWS environment variables


#### Using Static Credentials

| Terraform Variable | AWS Environment Variable | Description | 
| :--- | :--- | :--- |
| `aws_access_key_id` | `AWS_ACCESS_KEY_ID` | aws key |
| `aws_secret_access_key` | `AWS_SECRET_ACCESS_KEY` | aws key secret |
| `aws_session_token` | `AWS_SESSION_TOKEN` | session token for validating temporary credentials |

#### Using AWS Profile
| Terraform Variable | AWS Environment Variable | Description | 
| :--- | :--- | :--- |
| `aws_profile` | `AWS_PROFILE` | name of AWS Profile in the credentials file |
| `aws_shared_credentials_file` | `AWS_SHARED_CREDENTIALS_FILE` | location of credentials file. Default is `$HOME/.aws/credentials` on Linux and macOS, and `"%USERPROFILE%\.aws\credentials"` on Windows |


Find more information in the [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).


If you are using environemtn

