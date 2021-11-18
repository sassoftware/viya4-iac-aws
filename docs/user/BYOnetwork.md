# Supported Scenarios and Requirements for Using Existing Network Resources

You have the option to use existing network resources with SAS Viya 4 Terraform scripts. The table below summarizes the supported scenarios, requirements, and remaining resources that must still be created using the viya4-iac-aws project.

**NOTE:** We refer to the use of existing resources as "bring your own" or "BYO" resources.

| Scenario|Required Variables|Additional Requirements|Resources to be Created|
| :--- | :--- | :--- | :--- |
| 1. To work with an existing VPC | `vpc_id` | <ul><li>VPC does not contain any Subnets or other [Network components](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Networking.html)</li><li>VPC block size must be IPv4 with '/16' netmask (supports 65,536 IP addresses)</li><li>`DNS hostnames` and `DNS resolution` are enabled</li><li>[`subnets`](../CONFIG-VARS.md#networking) CIDR blocks must match with VPC IPv4 CIDR block</li></ul> | Subnets, NAT Gateway and Security Group|
| 2. To configure all components of your VPC network - Subnets, Routes & associations, Internet and NAT Gateways | `vpc_id`, <br>`subnet_ids` and <br>`nat_id` | <ul><li>all requirements from Scenario #1</li><li>Subnets Availability Zones must be within the [location](../CONFIG-VARS.md#required-variables)</li><li>AWS Tags with `<prefix>` value replaced with the [prefix](../CONFIG-VARS.md#required-variables) input value for <br>- Public Subnets:<ul><li>`{"kubernetes.io/role/elb"="1"}`</li><li>`{"kubernetes.io/cluster/<prefix>-eks"="shared"}`</li></ul>-Private Subnets:<ul><li>`{"kubernetes.io/role/internal-elb"="1"}`</li><li>`{"kubernetes.io/cluster/<prefix>-eks"="shared"}`</li></ul>See [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) for background on subnet tag requirements to match EKS Cluster name| Security Group |
| 3. To configure all components of your VPC network and Security Groups | `vpc_id`,<br>`subnet_ids`, <br>`nat_id`, <br>`security_group_id`, <br>`cluster_security_group_id`, and <br>`workers_security_group_id` |<ul><li>all requirements from Scenarios #2 and [these pre-defined Security Groups](#security-groups)</li></ul>| None |


### Security Groups

#### External Access Security Group

This Security Group is used to set external access to the Jump/NFS VMs and Postgres.

| | Protocol | Ports | Source | Destination|
| :--- | :--- | :--- | :--- | :--- |
| Outbound | All | All |  | 0.0.0.0/0 |
| Inbound PostgreSQL external | TCP | 5432 | <optional> the value you would set for the [`postgres_public_access_cidrs`](../CONFIG-VARS.md#admin-access) variable | |
| Inbound ssh access for JUMP/NFS VMs | TCP | 22 | the value you would set for the [`vm_public_access_cidrs`](../CONFIG-VARS.md#admin-access) variable ||

#### Cluster Security Group

Allow communication from Node VMs to Cluster control plane.

| | Protocol | Ports | Source | Destination|
| :--- | :--- | :--- | :--- | :--- |
| Outbound | All | All |  | 0.0.0.0/0 |
| Inbound from Node VMs to Cluster api | TCP | 443 | workers security group | |

#### Workers Security Group

Allow communication among Node VMs, from Cluster control plane to Node VMs and between Node VMs, Jump VM, and data sources (efs, nfs, postgres).

| | Protocol | Ports | Source | Destination|
| :--- | :--- | :--- | :--- | :--- |
| Outbound | All | All |  | 0.0.0.0/0 |
| Inbound allow workers to talk to each other | All | All | self ||
| Inbound from cluster control plane | TCP |1025 - 65535 | Cluster security group ||
| Inbound from cluster control plane | TCP | 443 | Cluster Security Group ||

This security group also needs the following tag:
`"kubernetes.io/cluster/<cluster name>" = "owned"`

For more information on these Security Groups, please see https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html.

When creating your BYO Network resources you should consult with your Network Administrator and use any of these methods to create a working AWS VPC Network:
- [AWS QuickStarts for VPC](https://aws.amazon.com/quickstart/architecture/vpc/)
- See the "simple-vpc" and "complete-vpc" examples in [terraform-aws-vpc module](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples) 

AWS documentation for reference:  
- [How Amazon VPC works](https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html)
- [VPC and subnet sizing for IPv4](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4)

To plan your subnet CIDR blocks for IP address ranges, here are some helpful links:
- https://network00.com/NetworkTools/IPv4AddressPlanner/
- https://www.davidc.net/sites/default/subnets/subnets.html
