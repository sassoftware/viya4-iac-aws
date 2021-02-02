# Using the Terraform CLI

## Prereqs

When using the Terraform CLI, make sure you have all the necessary tools [installed on your workstation](../../README.md#terraform).

## Preparation

### Set AWS Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to access AWS](./TerraformAWSAuthentication.md) and set all the environment variables using `export` command.

*TIP:* These commands can be stored in a file outside of this repo in a secure file, for example `$HOME/.azure_creds.sh`. Protect that file so only you have read access to it. Then source your credentials into your shell environment:

```bash
. $HOME/.aws_creds.sh
```

### Pepare Variable Definitions (.tfvars) File

Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).


## Running Terraform Commands

### Initialize Terraform Environment

Initialize the Terraform environment for this project by running

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes Terraform plugins and modules used in this project.

**NOTE:** `terraform init` only needs to be run once unless new Terraform plugins/modules were added.

### Preview Cloud Resources (optional)

To preview the resources that the Terraform script will create, run

```bash
terraform plan
```
### Create Cloud Resources

To create cloud resources, run

```bash
terraform apply
```

This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. The 'KUBECONFIG' file for the cluster is written to `[prefix]-eks-kubeconfig.conf` in the current directory `$(pwd)`.


### Display Terrafrom Output

Once the cloud resources have been created with `terraform apply` command, Terraform output values can be displayed later at any time again by running

```bash
terraform output
```

### Modify Cloud Resources

After provisioning the infrastructure, if further changes were to be made then add the variable and desired value to `terraform.tfvars` and run `terrafom apply` again.


### Tear Down Cloud Resources

To destroy all the cloud resources created with the previous comamnds, run

```bash
terraform destroy
```
**NOTE:** The '*destroy*' action is irreversible.

## Interacting with the Kubernetes cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file `./[prefix]-eks-kubeconfig.conf.` When the Kubernetes cluster is ready, use `kubectl` to interact with the cluster.

**NOTE:** This requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### Example Using `kubectl`

```bash
export KUBECONFIG=$(pwd)/<your prefix>-eks-kubeconfig.conf
kubectl get nodes
```
