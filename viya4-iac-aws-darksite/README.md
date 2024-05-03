# Using the `viya4-iac-aws` GitHub project in a Dark Site Deployment Scenario (Experimental)

### Contributors

We thank the following individuals for technical assistance and their contributions for the documentation, scripts and yaml templates that provided the basis for this document.
- Josh Coburn
- Matthias Ender

### Background for Dark Site Deployment Scenarios

This documentation contains procedures that can be used to successfully complete the EKS cluster provisioning portion of a Viya Dark Site deployment using elements of the `viya4-iac-aws` GitHub project decribed below.

#### Dark Site Deployment Target Recommendation
**Note:** _It is recommended for a Dark Site deployment that you use a [BYON](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/user/BYOnetwork.md) or Bring Your Own Network configuration (scenario 3)  with IAC by creating your own VPC, Subnets, AWS private endpoints, and Network Security Groups versus letting `viya4-iac-aws` create these items for you.  If you rely on `viya4-iac-aws` to create the network infrastructure in a Dark Site scenario, you will likely run into failure points.  The procedures listed below assume that you use a BYON configuration scenario with IAC._

### Procedures

1.  **Build a Private VPC for EKS:**

    - **Note:** _Creating AWS VPCs for an EKS cluster can be accomplished in many different ways. Some of those methods include using a CloudFormation template, the AWS console, the AWS CLI, or Terraform scripts._

    - **Note**: If you have an existing VPC environment consisting of a private VPC and a public VPC (optional) that constitute a Dark Site configuration, skip to the **_Create Custom AMI for Jumpserver/NFSServer_** in step #2 below.

    - Background Information - AWS Reference documentation with details on how to create a VPC for any EKS cluster: https://docs.aws.amazon.com/eks/latest/userguide/creating-a-vpc.html

    - For the cluster VPC ranges, `viya4-iac-aws` defaults to using a CIDR of /16. The `viya4-iac-aws` project creates a /21 VPC with both /22 and /28 sized subnets.  Excluding the `control_plane` subnets, the sizes were chosen by estimating the number of pods (doubling that number to account for viya updates), services, AWS overhead, and then adding a few hundred as a buffer.  

2.  **Create Custom AMI for Jumpserver/NFSServer**
    - The standard base AMI image used by `viya4-iac-aws` does not include the required NFS related Linux distributution packages.  Normally, `viya4-iac-aws` will attempt to install the NFS packages as part of the VM initialization.  In a Dark Site without access to Internet based resources, installation from an Internet based repository will not be possible.  To mitigate that issue, we'll need to create a custom AMI and then modify the local copy of our `viya4-iac-aws` repository to add references to that custom AMI as well as remove some of the initialization steps in the cloud-init files (for jumpserver and nfs-server). 

    - Instructions to complete the custom AMI creation steps can be found [here](https://github.com/sassoftware/viya4-iac-aws/tree/feat/iac-1117/viya4-iac-aws-darksite/custom-ami/) [here](https://github.com/sassoftware/viya4-iac-aws/tree/main/viya4-aws-darksite/custom-ami/).

    <p>_*TODO*_: Should these next 2 paras only appear in the README_Internal.md file?</p>

3.  **Build tfvars:**
    - The Terraform scripts create the necessary BYON subnet_ids. When running`viya4-iac-aws` from your deployment VM with the PrivateVPC as the target for your Kubernetes EKS cluster, `viya4-iac-aws` should be configured to use those BYO subnets for all the subnet_ids map BYON variables in the tfvars file (public, private, control_plane and database).
    - Do not specify any public access CIDRs in your tfvars file.
    - Set `cluster_api_mode` to private.

4.  **Deploy viya4-iac-aws:**
    - Ensure that the deployment machine has a route and is allowed ingress to the cluster control plane before attempting a deployment. Executing a `kubectl` command such as `kubectl get nodes` from the deployment VM in the public VPC can be used to confirm connectivty to the EKS control plane.
