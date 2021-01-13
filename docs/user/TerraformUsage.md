# Using the Terraform CLI

When using the terraform CLI, make sure you have all the necessary tools [installed on your workstation](../../README.md#terraform).

## Set AWS Authentication

Prepare a file with authentication info, as described in [Authenticating Terraform to access AWS](./docs/user/TerraformAWSAuthentication.md)

Then source your credentials into your shell enviornment

```bash
. $HOME/.azure_creds.sh
```

## Pepare User Variables

Prepare your `terraform.tfvars` file, as described in Also. prepare a file with authentication info, as described in [Authenticating Terraform to access AWS](../../README.md#customize_input_values).


## Initialize Terraform 

Initialize the Terraform environment for this project by running

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes Terraform plugins/modules used in this project.

**Note:** `terraform init` only needs to be run once unless new Terraform plugins/modules were added.

## Preview Resources

To preview the resources that the Terraform script will create, optionally run

```bash
terraform plan
```
## Create Resources

When satisfied with the plan and ready to create cloud resources, run

```bash
terraform apply
```

`terraform apply` can take a few minutes to complete. Once complete, output values are written to the console. 

## View Outputs

The output values can be displayed later at any time again by running

```bash
terraform output
```

## Tear down Resources

To destroy the kubernetes cluster and all related resources, run

```bash
terraform destroy
```
NOTE: The "destroy" action is destructive and irreversible.

## Modifying Cloud Resources

After provisioning the infrastructure, if further changes were to be made then add the variable and desired value to terraform.tfvars and run `terrafom apply` again.

## Interacting with Kubernetes cluster

Terraform script writes the `kube_config` output value to a file `./[prefix]-eks-kubeconfig.conf`. Now that you have your Kubernetes cluster up and running, use `kubectl` to interact with our cluster.

**Note** this requires `cluster_endpoint_public_access_cidrs` value to be set to your local ip or CIDR range.

### `kubectl` Example

```bash
export KUBECONFIG=./<your prefix>-eks-kubeconfig.conf
kubectl get nodes
```
