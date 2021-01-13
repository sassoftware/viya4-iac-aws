


#### Docker
### Building the docker image

Run the following command to create your `viya4-iac-aws` local docker image

```bash
docker build -t viya4-iac-aws .
```

##### Preparation

When using the Docker container you need to make sure that all file references in your `terraform.tfvars` file are accessible inside the container. The easiest way to achieve this is to make sure that the files specified in the following variables are stored within your project directory:

| Name | Description | 
| :--- | :--- |   
| ssh_public_key | Filename of the public ssh key to use for all VMs | 

Then copy `terraform.tfvars` file to `terraform.docker.tfvars` and modify the paths to those variables to use `/workspace/<relative filename in the current project directory>`, because your current project directory will be mounted as `/workspace` within the container.

##### Sample Actions

To preview the resources that the Terraform script will create, optionally run

```bash
docker run --rm -u "$UID:$GID" \
  --env-file $HOME/.aws_docker_creds.env \
  -v $(pwd):/workspace \
  viya4-iac-aws \
  plan -var-file=/workspace/terraform.docker.tfvars \
       -state /workspace/terraform.tfstate  
```

When satisfied with the plan and ready to create cloud resources, run

```bash
docker run --rm -u "$UID:$GID" \
  --env-file $HOME/.aws_docker_creds.env \
  -v $(pwd):/workspace \
  viya4-iac-aws \
  apply -auto-approve \
        -var-file=/workspace/terraform.docker.tfvars \
        -state /workspace/terraform.tfstate 
```
`terraform apply` can take a few minutes to complete. Once complete, output values are written to the console.

The output values can be displayed anytime by again running

```bash
docker run --rm -u "$UID:$GID" \
  viya4-iac-aws \
  output -state /workspace/terraform.tfstate 
 
```

To destroy the kubernetes cluster and all related resources, run

```bash
docker run --rm -u "$UID:$GID" \
  --env-file $HOME/.aws_docker_creds.env \
  -v $(pwd):/workspace \
  viya4-iac-aws \
  destroy -auto-approve \
          -var-file=/workspace/terraform.docker.tfvars \
          -state /workspace/terraform.tfstate
```
NOTE: The "destroy" action is destructive and irreversible.


### Modifying Cloud Resources

After provisioning the infrastructure if further changes were to be made then add the variable and desired value to terraform.tfvars and run `terrafom apply` again.

### Interacting with Kubernetes cluster

Terraform script writes `kube_config` output value to a file `./[prefix]-eks-kubeconfig.conf`. Now that you have your Kubernetes cluster up and running, here's how to connect to the cluster:

**Note** this requires `cluster_endpoint_public_access_cidrs` value to be set to your local ip or CIDR range.

#### Terraform

```bash
export KUBECONFIG=./<your prefix>-eks-kubeconfig.conf
kubectl get nodes
```

#### Docker

```bash
docker run --rm \
  -e KUBECONFIG=/workspace/<your prefix>-eks-kubeconfig.conf \
  -v $(pwd):/workspace \
  --entrypoint kubectl \
  viya4-iac-gcp get nodes 

```


### Examples

