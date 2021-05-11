## Supported scenarios and requirements when using existing network resources

The table below shows the supported scenarios when using existing/bring your own(BYO) network resources:

| Scenario|Required variables|Additional requirements|Resources to be created|
| :--- | :--- | :--- | :--- |
| 1. When you have to work with an existing VPC | `vpc_id` | <ul><li>VPC does not contain any Subnets or other [Network components](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Networking.html)</li><li>VPC block size must be IPv4 with '/16' netmask (supports 65,536 IP addresses)</li><li>`DNS hostnames` and `DNS resolution` are enabled</li><li>[`subnets`](../CONFIG-VARS.md#networking) CIDR blocks must match with VPC IPv4 CIDR block</li></ul> | Subnets, NAT Gateway and Security Group|
| 2. When you want to configure all components of your VPC network - Subnets, Routes & associations, Internet and NAT Gateways | `vpc_id`, <br>`subnet_ids` and <br>`nat_id` | <ul><li>This must be a <b>fully functional AWS VPC Network</b></li><li>VPC block size must be IPv4 with '/16' netmask (supports 65,536 IP addresses)</li><li>`DNS hostnames` and `DNS resolution` are enabled</li><li>`subnet_ids` CIDR blocks must match with VPC IPv4 CIDR block</li><li>Subnets Availability Zones must be within the [location](../CONFIG-VARS.md#required-variables)</li><li>AWS Tags with `<prefix>` value replaced with the [prefix](../CONFIG-VARS.md#required-variables) input value for <br>- Public Subnets:<ul><li>`{"kubernetes.io/role/elb"="1"}`</li><li>`{"kubernetes.io/cluster/<prefix>-eks"="shared"}`</li></ul>-Private Subnets:<ul><li>`{"kubernetes.io/role/internal-elb"="1"}`</li><li>`{"kubernetes.io/cluster/<prefix>-eks"="shared"}`</li></ul>See [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) for background on subnet tag requirements to match EKS Cluster name| Security Group |
| 3. When you want to configure all components of your VPC network and Security Group | `vpc_id`,<br>`subnet_ids`, <br>`nat_id`, and <br>`security_group_id` |<ul><li>all requirements from Scenarios #2 and additionally</li></ul>| None |
||||||


When creating your BYO Network resources you should consult with your Network Administrator and use any of these methods to create a working AWS VPC Network
- [AWS QuickStarts for VPC](https://aws.amazon.com/quickstart/architecture/vpc/)
- See 'simple-vpc' and 'complete-vpc' examples in [terraform-aws-vpc module](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples) 

AWS docs for reference:
- [How Amazon VPC works](https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html)
- [AWS VPC Subnet sizing](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4)

To plan your Subnet CIDR blocks for IP ranges, here are some helpful links:
- https://network00.com/NetworkTools/IPv4AddressPlanner/
- https://www.davidc.net/sites/default/subnets/subnets.html
