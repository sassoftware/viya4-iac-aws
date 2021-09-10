# Supported Scenarios and Requirements for Using Existing Network Resources

You have the option to use existing network resources with SAS Viya 4 Terraform scripts. The table below summarizes the supported scenarios, requirements, and remaining resources that must still be created using the viya4-iac-aws project.

**NOTE:** We refer to the use of existing resources as "bring your own" or "BYO" resources.

| Scenario|Required Variables|Additional Requirements|Resources to be Created|
| :--- | :--- | :--- | :--- |
| 1. You must work with an existing VPC. | `vpc_id` | <ul><li>VPC does not contain any subnets or other network components. See the [AWS guide to VPC Networking](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Networking.html) for more information</li><li>VPC block size must be IPv4 with '/16' subnet mask (supports 65,536 IP addresses)</li><li>`DNS hostnames` and `DNS resolution` are enabled</li><li>The values for the [`subnets` variable](../CONFIG-VARS.md#networking) must match the VPC IPv4 CIDR block</li></ul> | Subnets, NAT gateway, and Security Group |
| 2. You want to configure all components of your VPC network &mdash; subnets, routes and associations, internet and NAT gateways. | `vpc_id`, <br>`subnet_ids`, and <br>`nat_id` | <ul><li>This must be a <b>fully functional AWS VPC Network</b></li><li>VPC block size must be IPv4 with '/16' subnet mask (supports 65,536 IP addresses)</li><li>AWS **DNS hostnames** and **DNS resolution** settings must be enabled</li><li>The CIDR blocks defined for `subnet_ids` must match the VPC IPv4 CIDR block</li><li>Subnet Availability Zones must be within the location defined in [CONFIG-VARS](../CONFIG-VARS.md#required-variables)</li><li>AWS tags with `<prefix>` value replaced with the [prefix](../CONFIG-VARS.md#required-variables) input value for <br>- **Public Subnets:**<ul><li>`{"kubernetes.io/role/elb"="1"}`</li><li>`{"kubernetes.io/cluster/<prefix>-eks"="shared"}`</li></ul>- **Private Subnets:**<ul><li>`{"kubernetes.io/role/internal-elb"="1"}`</li><li>`{"kubernetes.io/cluster/<prefix>-eks"="shared"}`</li></ul>See the [AWS user documentation](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) for information about subnet tag requirements to match the EKS cluster name. | Security Group |
| 3. You want to configure all components of your VPC network and Security Group. | `vpc_id`,<br>`subnet_ids`, <br>`nat_id`, and <br>`security_group_id` | All requirements from Scenario #2 and the Security Group. | None |
||||||

## Helpful Resources
  
When creating your BYO network resources, consult with your Network Administrator and use any of the methods documented in the following resources to create a working AWS VPC network:  
- [AWS QuickStarts for VPC](https://aws.amazon.com/quickstart/architecture/vpc/)
- See the "simple-vpc" and "complete-vpc" examples in [terraform-aws-vpc module](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples) 

AWS documentation for reference:  
- [How Amazon VPC works](https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html)
- [VPC and subnet sizing for IPv4](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4)

To plan your subnet CIDR blocks for IP address ranges, here are some helpful links:
- https://network00.com/NetworkTools/IPv4AddressPlanner/
- https://www.davidc.net/sites/default/subnets/subnets.html
