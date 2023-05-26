# Using a Docker Container to Run Terraform

## Prerequisites

- Docker must be [installed on your workstation](../../README.md#docker-requirements).

### Create the Docker Image

Run the following command to create the `viya4-iac-aws` Docker image using the provided [dockerfile](../../Dockerfile):

```bash
docker build -t viya4-iac-aws .
```

The Docker image, `viya4-iac-aws`, contains Terraform and kubectl executables. The entrypoint for the Docker image is `terraform`. The entrypoint will be run with subcommands in the subsequent steps.

### Docker Environment File For AWS Authentication

Follow either one of the authentication methods described in [Authenticating Terraform to Access AWS](./TerraformAWSAuthentication.md) in order to configure authentication and enable container invocation. Store these values outside of this repository in a secure file, for example
`$HOME/.aws_docker_creds.env.` Protect that file so that only you have Read access to it.

> **NOTE:** Do not use quotation marks around the values in the file, and be sure to avoid any trailing blank spaces.

Now each time you invoke the container, specify the file with the [`--env-file` option](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file) in order to pass AWS credentials to the container.

### Docker Volume Mounts

Add volume mounts to the `docker run` command for all files and directories that must be accessible from inside the container:

- `--volume=$HOME/.ssh:/.ssh` for [`ssh_public_key`](../CONFIG-VARS.md#required-variables) variable in the `terraform.tfvars` file
- `--volume=$(pwd):/workspace` for a local directory where the `terraform.tfvars` file resides and where the `terraform.tfstate` file will be written.

    To grant Docker permission to write to the local directory, use the [`--user` option](https://docs.docker.com/engine/reference/run/#user).

**NOTE:** Local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.

### Variable Definitions (.tfvars) File

Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Running Terraform Commands

### Preview Cloud Resources (Optional)

To preview the cloud resources before creating them, run the Docker image (`viya4-iac-aws`) with the `plan` command:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file $HOME/.aws_docker_creds.env \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-aws \
  plan -var-file /workspace/terraform.tfvars \
       -state /workspace/terraform.tfstate
```

### Create Cloud Resources

To create the cloud resources, run the `viya4-iac-aws` Docker image with the `apply` command and the `-auto-approve` option:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file $HOME/.aws_docker_creds.env \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-aws \
  apply -auto-approve \
        -var-file /workspace/terraform.tfvars \
        -state /workspace/terraform.tfstate
```

This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. The `kubeconfig` file for the cluster is written to `[prefix]-eks-kubeconfig.conf` in the current directory, `$(pwd)`.

### Display Terraform Outputs

Once the cloud resources have been created using the `terraform apply` command, you can display Terraform output values by running the `viya4-iac-aws` Docker image using the `output` command:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume $(pwd):/workspace \
  viya4-iac-aws \
  output -state /workspace/terraform.tfstate
```

### Modify Cloud Resources

After provisioning the infrastructure, you can make additional modifications. Update the corresponding variables with the desired values in `terraform.tfvars`. Then run the Docker image with the `apply` command and `-auto-approve` option again:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file $HOME/.aws_docker_creds.env \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-aws \
  apply -auto-approve \
        -var-file /workspace/terraform.tfvars \
        -state /workspace/terraform.tfstate
```

### Tear Down Resources

To destroy all the cloud resources that you created with the previous commands, run the `viya4-iac-aws` Docker image with the `destroy` command and `-auto-approve` option:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file $HOME/.aws_docker_creds.env \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-aws \
  destroy -auto-approve \
          -var-file /workspace/terraform.tfvars \
          -state /workspace/terraform.tfstate
```

> **NOTE:** The `destroy` action is irreversible.

## Interacting with the Kubernetes Cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file, `./[prefix]-eks-kubeconfig.conf`. When the Kubernetes cluster is ready, use `--entrypoint kubectl` to interact with the cluster.

> **NOTE** The [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value in CONFIG-VARS.md must be set to your local IP address or CIDR range.

### Example Using `kubectl`

You can run the `kubectl get nodes` command with the `viya4-iac-aws` Docker image in order to get a list of cluster nodes. Switch the entrypoint to kubectl (`--entrypoint kubectl`), provide a kubeconfig file (`--env=KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf`), and pass kubectl subcommands (such as `get nodes`). For example, to run `kubectl get nodes`, run one of the following commands that matches your kubeconfig file type:

Using a static kubeconfig file

```bash
docker run --rm \
  --env=KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf \
  --volume=$(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-aws get nodes
```

Using a provider based kubeconfig file requires AWS cli credentials in order to authenticate to the cluster

```bash
docker run --rm \
  --env=KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf \
  --volume=$(pwd):/workspace \
  --env=AWS_PROFILE=default \
  --env=AWS_SHARED_CREDENTIALS_FILE=/workspace/credentials \
  --volume $HOME/.aws/credentials:/workspace/credentials \
  --entrypoint kubectl \
  viya4-iac-aws get nodes
```
See [Kubernetes Configuration File Generation](./Kubeconfig.md) for information related to creating static and provider based kube config files.

You can find more information about using AWS CLI credentials in [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-profiles).
