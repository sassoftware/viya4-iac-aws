# Docker

When using the terraform CLI, make sure you have docker [installed on your workstation](../../README.md#docker).

Also prepare a file with authentication info, as described in [Authenticating Terraform to access AWS](./TerraformAWSAuthentication.md)

## Build the docker image

Run the following command to create your `viya4-iac-aws` local docker image

```bash
docker build -t viya4-iac-aws .
```

## Preparation

When using the Docker container you need to make sure that all file references in your `terraform.tfvars` file are accessible inside the container. Add mounts to those files (or the directories that contain them) to the Container. Note that local references to `$HOME` (or "`~`") need to map to the root directory `/` in the container.

| Name | Description | 
| :--- | :--- |   
| ssh_public_key | Filename of the public ssh key to use for all VMs |

## Preview the Cloud Resources

To preview the resources that the Terraform script will create, optionally run

```bash
docker run --rm -u "$(id -u)" \
  --env-file $HOME/.aws_creds.env \
  -v $HOME/.ssh:/.ssh \
  -v $(pwd):/workspace \
  viya4-iac-aws \
  plan -var-file=/workspace/terraform.tfvars \
       -state /workspace/terraform.tfstate  
```

## Create Resources

When satisfied with the plan and ready to create the cloud resources, run

```bash
docker run --rm -u "$(id -u)" \
  --env-file $HOME/.aws_docker_creds.env \
  -v $HOME/.ssh:/.ssh \
  -v $(pwd):/workspace \
  viya4-iac-aws \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state /workspace/terraform.tfstate 
```
`terraform apply` can take a few minutes to complete. Once complete, output values are written to the console.

## Display Outputs

The output values can be displayed anytime by again running

```bash
docker run --rm -u "$(id -u)" \
  viya4-iac-aws \
  output -state /workspace/terraform.tfstate 
 
```

## Tear Down Resources 

To destroy the kubernetes cluster and all related resources, run

```bash
docker run --rm -u "$(id -u)" \
  --env-file $HOME/.aws_docker_creds.env \
  -v $HOME/.ssh:/.ssh \
   -v $(pwd):/workspace \
  viya4-iac-aws \
  destroy -auto-approve \
          -var-file=/workspace/terraform.tfvars \
          -state /workspace/terraform.tfstate
```
NOTE: The "destroy" action is destructive and irreversible.

## Modify Cloud Resources

After provisioning the infrastructure if further changes were to be made then add the variable and desired value to `terraform.tfvars` and run `terrafom apply` again:

```bash
docker run --rm -u "$(id -u)" \
  --env-file $HOME/.aws_docker_creds.env \
  -v $HOME/.ssh:/.ssh \
   -v $(pwd):/workspace \
  viya4-iac-aws \
  apply -auto-approve \
        -var-file=/workspace/terraform.tfvars \
        -state /workspace/terraform.tfstate 
```

## Interacting with Kubernetes cluster

The Terraform script writes the `kube_config` output value to a file `./[prefix]-eks-kubeconfig.conf`. Now that you have your Kubernetes cluster up and running, use `kubectl` to interact with our cluster.

**Note** this requires [`cluster_endpoint_public_access_cidrs`](../CONFIG-VARS.md#admin-access) value to be set to your local ip or CIDR range.

#### `kubectl` Example

```bash
docker run --rm \
  -e KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf \
  -v $(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-gcp get nodes 

```

