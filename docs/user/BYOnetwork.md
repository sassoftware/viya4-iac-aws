## Supported scenarios and requirements for using existing AWS network resources

The table below shows the scenarios supported with using existing/bring your own(BYO) network resources:

| <div style="width:70px">Scenario</div> | <div style="width:70px">BYO resource</div> | <div style="width:500px">Requirements</div> | <div style="width:100px">Resources that will be created</dvi>|
| :--- | :--- | :--- | :--- |
| 1 | VPC | <ul><li>VPC block size must be IPv4 CIDR block with '/16' netmask (supports 65,536 IP addresses)</li><li>`DNS hostnames` and `DNS resolution` are enabled</li><li>`var.vpc_id` must be provided</li><li>`var.subnets` CIDR blocks must match with VPC CIDR IPv4 CIDR block</li></ul> | Subnets (NAT_id, routes and Route Table association) and Security Group|
| 2 | - VPC, <br>- Subnets with NAT<ul><li>Public</li><li>Private</li><li>Database(only when `var.create_postgres=true`)</li></ul>  | <ul><li>all requirements from Scenario #1 and additionally</li><li>`var.vpc_id`, `var.subnet_ids` must be provided</li><li>AWS Tags for Public Subnets must have these tags with `var.prefix` value replaced to match EKS Cluster name, see [AWS docs](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) for details <br>- `{"kubernetes.io/role/elb"="1" }`,<br>- `{"kubernetes.io/cluster/${var.prefix}-eks"="shared" }`</li><li>AWS Tags for Private Subnets must have these tags with `var.prefix` value replaced<br>- `{ "kubernetes.io/role/internal-elb"="1" }`,<br>- `{"kubernetes.io/cluster/${var.prefix}-eks"="shared" }`</li></ul>| VPC and Subnets will be used and Security Group will be created|
| 3 | - VPC, <br>- Subnets with NAT<ul><li>Public</li><li>Private</li><li>Database(only when `var.create_postgres=true`)</li></ul>- Security Group |<ul><li>all requirements from Scenarios # 1 & 2 and additionally</li><li>`var.security_group_id` must be provided</li></ul>| None |


<br>
When creating your BYO Network resources you should consult with your Network Administrator and use any of these methods to create a working AWS VPC Network
- AWS QuickStarts - https://aws.amazon.com/quickstart/architecture/vpc/
- Terraform Modules - see 'simple-vpc' or 'complete-vpc' examples in https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examplesyou 

AWS docs for reference:
- [How Amazon VPC works](https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html)
- [AWS VPC Subnet sizing](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#vpc-sizing-ipv4)

To plan your Subnet CIDR blocks for IP ranges, here are some helpful links:
- https://network00.com/NetworkTools/IPv4AddressPlanner/
- https://www.davidc.net/sites/default/subnets/subnets.html
