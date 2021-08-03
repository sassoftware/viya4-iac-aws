# Using the Terraform Command-Line Interface

Use Terraform and the SAS IaC tools to create a Kubernetes cluster for your SAS Viya deployment.

## Prepare the Environment

### Prerequisites

When using the Terraform CLI, make sure you have all the necessary tools [installed on your workstation](../../README.md#terraform-requirements).

### Set Up AWS Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to Access AWS](./TerraformAWSAuthentication.md) and set all the environment variables using the `export` command.

> **TIP:** These commands can be stored in a directory outside of this repository in a secure file, for example in `$HOME/.aws_creds.sh`. Protect that file so that only you have Read access to it. Then source your credentials into your shell environment:

```bash
. $HOME/.aws_creds.sh
```

### Customize the Variable Definitions File (tfvars)

Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Run Terraform Commands

### Initialize Terraform Environment

Initialize the Terraform environment for this project by running the following command:

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes the Terraform plug-ins and modules that are used in this project.

> **NOTE:** The `terraform init` command only needs to be run once unless new Terraform plug-ins and modules are added.

### Preview Cloud Resources (Optional)

To preview the resources that the Terraform script will create, run the following command:

```bash
terraform plan
```

### Create Cloud Resources

To create cloud resources, run the following command:

```bash
terraform apply
```

This command can take a few minutes to complete. Once it has completed, Terraform output values are written to the console. The `kubeconfig` file for the cluster is written to `[prefix]-eks-kubeconfig.conf` in the current directory, `$(pwd)`.

### Display Terrafrom Output

Once the cloud resources have been created using the `terraform apply` command, Terraform output values can be displayed again later at any time by running the following command:

```bash
terraform output
```

### Modify Cloud Resources

After provisioning the infrastructure, you can make additional changes by modifying `terraform.tfvars` and running `terrafom apply` again.

### Tear Down Cloud Resources

To destroy all the cloud resources created with the previous comamnds, run the following command:

```bash
terraform destroy
```

> **NOTE:** The `destroy` action is irreversible.

## Interacting with the Kubernetes Cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file, `./[prefix]-eks-kubeconfig.conf.` When the Kubernetes cluster is ready, use `kubectl` to interact with the cluster.

**NOTE:** The value for [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) in CONFIG-VARS.md must be set to your local IP address or CIDR range.

### Example Using `kubectl`

```bash
export KUBECONFIG=$(pwd)/<your prefix>-eks-kubeconfig.conf
kubectl get nodes
```
