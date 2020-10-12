### Authenticating Terraform to access AWS

Terraform supports multiple ways of authenticating to AAWS. This project chooses to use Environment Variables, see [Terraform documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables). In order to create and destroy AWS resources on your behalf, Terraform also needs information about AWS Profile. 

You can [set these variables in your `main.tf` file](../../main.tf) by adding the entries to the `provider` block which when updated would look like:

```
provider "aws" {
  region = "us-east-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}
```

But since they contain sensitive information, we recommend to use environment variables instead.

Run these commands to initialize the environment for the project. These commands will need to be run and pulled  into your environment each time you start a new session to use this repo and terraform.

```
# export needed ids and secrets
export AWS_ACCESS_KEY_ID=[Access key ID]
export AWS_SECRET_ACCESS_KEY=[Secret access key]
export AWS_DEFAULT_REGION='us-east-1'
```

**TIP:** These commands can be stored in a file outside of this repo in a secure file. \
Use your favorite editor, take the content above and save it to a file called: `$HOME/.aws_creds.sh` . (Protect that file so only you have read access to it.) \
Now each time you need these values you can do the following:

```
source $HOME/.aws_creds.sh
```

This will pull in those values into your current terminal session. Any terraform commands submitted in that session will use those values.

