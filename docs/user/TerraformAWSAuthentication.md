### Authenticating Terraform to access AWS

In order to create and destroy AWS objects on your behalf, Terraform needs to log in to AWS with an identity that has sufficient permissions to perform all the actions defined in the terraform manifest.

You will need an `user` that has at a mininum the permissions listed in [this policy](../../files/devops-iac-eks-policy.json).

You can use either static credentials (including temporary credentials with session token), or an AWS Profile.

You can pass the credentials into the Terraform AWS provider either by Terraform variables, or as AWS environment variables

#### Creating Authentication Resrouces

- [Creating an IAM user in your AWS account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
- [Using Profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-profiles)

#### Using Static Credentials

| Terraform Variable | AWS Environment Variable | Description | Type |
| :--- | :--- | :--- | ---: |
| `aws_access_key_id` | `AWS_ACCESS_KEY_ID` | aws key | string |
| `aws_secret_access_key` | `AWS_SECRET_ACCESS_KEY` | aws key secret | string |
| `aws_session_token` | `AWS_SESSION_TOKEN` | session token for validating temporary credentials | string |

#### Using AWS Profiles

| Terraform Variable | AWS Environment Variable | Description | Type |
| :--- | :--- | :--- | ---: |
| `aws_profile` | `AWS_PROFILE` | name of AWS Profile in the credentials file | string |
| `aws_shared_credentials_file` | `AWS_SHARED_CREDENTIALS_FILE` | location of credentials file. Default is `$HOME/.aws/credentials` on Linux and macOS, and `"%USERPROFILE%\.aws\credentials"` on Windows | string |

Find more information in the [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).

## How to set the Terraform Authentication variables

We recommend to use environment variables to pass the authentication information into your terraform job.

You can use the `TF_VAR_` prefix to set your terraform variables as environment variables.

### Set Authentication Variables when running Terraform directly

Run these commands to initialize the environment for the project. These commands will need to be run and pulled  into your environment each time you start a new session to use this repo and terraform.

Example for using Static Credentials:

```bash
# export needed ids and secrets
export TF_VAR_aws_access_key_id="xxxxxxxxxx"
export TF_VAR_aws_secret_access_key="xxxxxxxxxx"
export TF_VAR_aws_session_token="xxxxxxxxxx"
```

or

```bash
# export needed ids and secrets
export AWS_ACCESS_KEY_ID="xxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxx"
export AWS_SESSION_TOKEN="xxxxxxxxxx"
```

**TIP:** These commands can be stored in a file outside of this repo in a secure file.
Use your favorite editor, take the content above and save it to a file called:
`$HOME/.aws_creds.sh` . (Protect that file so only you have read access to it.) Now each time you need these values you can do the following:

```bash
source $HOME/.aws_creds.sh
```

This will pull in those values into your current terminal session. Any terraform commands submitted in that session will use those values.

### Set Authentication Variables when running Docker container

When using the docker container to run terraform, create a file with the authentication variable assignments. You then specify that file at container invocation.

Example for using AWS Profiles:

```bash
# Needed ids and secrets for docker
AWS_PROFILE="xxxxxxxxxx"
AWS_SHARED_CREDENTIALS_FILE="xxxxxxxxxx"
```

Store these commands outside of this repo in a secure file, for example `$HOME/.aws_docker_creds.env` . (Protect that file so only you have read access to it.) Now each time you invoke the container, specify the file in the `--env-file` dDcker option, e.g.

```bash
docker <...> \
  --env-file $HOME/.aws_docker_creds.env \
  <...>
```

NOTE: When using `AWS_PROFILE`, the `AWS_SHARED_CREDENTIALS_FILE` location must be accessible from inside the container. Make sure to mount its location when invoking the Docker container, e.g.

```bash
docker <...> \
  -v $HOME/.aws/credentials:/.aws/credentials \
  <...>
```

(Note that local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.)
