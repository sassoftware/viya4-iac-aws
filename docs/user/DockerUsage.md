# Using Docker Container

## Prereqs

- Docker [installed on your workstation](../../README.md#docker).

## Preparation

### Docker Image

Run the following command to create the `viya4-iac-aws` Docker image using the provided [Dockerfile](../../Dockerfile). 

```bash
docker build -t viya4-iac-aws .
```

The Docker image `viya4-iac-aws` will contain Terraform and 'kubectl' executables. Entrypoint entrypoint for the Docker image is `terraform` that will be run with subcommands in the subsequent steps.

### Docker Environment File For AWS Authentication 

Follow either one of the authentication methods described in [Authenticating Terraform to access Azure](./TerraformAWSAuthentication.md) to use with container invocation. Store these values outside of this repo in a secure file, for example
`$HOME/.aws_docker_creds.env.` Protect that file so only you have read access to it. 

**NOTE:** Do not use quotes around the values in the file, and make sure to avoid any trailing blanks!

Now each time you invoke the container, specify the file with the [`--env-file` option](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file) to pass on AWS credentials to the container.


### Docker Volume Mounts

Add volume mounts to the `docker run` command for all files and directories that must be accessible from inside the container.
- `--volume=$HOME/.ssh:/.ssh` for [`ssh_public_key`](../CONFIG-VARS.md#required-variables) variable in the `terraform.tfvars` file
- `--volume=$(pwd):/workspace` for local directory where `terraform.tfvars` file resides and where `terraform.tfstate` file will be written. To grant Docker, permission to write to the local directory use [`--user` option](https://docs.docker.com/engine/reference/run/#user)

**NOTE:** Local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.

### Variable Definitions (.tfvars) File

Prepare your `terraform.tfvars` file, as described in [Customize Input Values](../../README.md#customize-input-values).

## Running Terraform Commands

### Preview Cloud Resources (optional)

To preview the cloud resources before creating, run the Docker image `viya4-iac-aws` with the `plan` command

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

To create the cloud resources, run the Docker image `viya4-iac-aws` with the `apply` command and `-auto-approve` option

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
This command can take a few minutes to complete. Once complete, Terraform output values are written to the console. The 'KUBECONFIG' file for the cluster is written to `[prefix]-eks-kubeconfig.conf` in the current directory `$(pwd)`.

### Display Terraform Outputs

Once the cloud resources have been created with `apply` command, to display Terraform output values, run the Docker image `viya4-iac-aws` with `output` command

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --volume $(pwd):/workspace \
  viya4-iac-aws \
  output -state /workspace/terraform.tfstate 
```

### Modify Cloud Resources

After provisioning the infrastructure if further changes were to be made then update corresponding variables with desired values in `terraform.tfvars` and run the Docker image `viya4-iac-aws` with the `apply` command and `-auto-approve` option again

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

To destroy all the cloud resources created with the previous commands, run the Docker image `viya4-iac-aws` with the `destroy` command and `-auto-approve` option

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
**NOTE:** The 'destroy' action is irreversible.

## Interacting with Kubernetes cluster

[Creating the cloud resources](#create-cloud-resources) writes the `kube_config` output value to a file `./[prefix]-eks-kubeconfig.conf`. When the Kubernetes cluster is ready, use `--entrypoint kubectl` to interact with the cluster.

**NOTE** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

### Example Using `kubectl`

To run `kubectl get nodes` command with the Docker image `viya4-iac-aws` to list cluster nodes, switch entrypoint to kubectl (`--entrypoint kubectl`), provide 'KUBECONFIG' file (`--env=KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf`) and pass kubectl subcommands(`get nodes`). For e.g., to run `kubectl get nodes`

```bash
docker run --rm \
  --env=KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf \
  --volume=$(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-aws get nodes
```
