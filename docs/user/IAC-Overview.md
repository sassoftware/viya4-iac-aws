# Infrastructure Items Created by the IaC Codebase

The items are created in their dependency order determined by Terraform during runtime. They are placed in the order below on how they logically fall within the Terraform files.

## VPC

[IAC VPC Code](https://github.com/sassoftware/viya4-iac-aws/tree/main/modules/aws_vpc)

- **VPC**
  - This item is created by the IaC code base unless provided by the customer

- **VPC Private Endpoints**
  - These provide the needed communication between AWS, its items, and the running cluster
  - [Documentation from AWS on Private EKS clusters](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html) and service and endpoint considerations
    **NOTE:** These are added to the VPC security groups created
    - ec2 (Interface)
    - ecr.api (Interface)
    - ecr.dkr (Interface)
    - s3 (Interface)
    - logs (Interface)
    - sts (Interface)
    - elasticloadbalancing (Interface)
    - autoscaling (Interface)

- **Subnets**
  - These items are created by the IaC code base unless provided by the customer
  - They are:
    - Private
    - Control Plane
    - Public (Optional with BYO scenario 2)
    - Database (Optional with BYO scenario 2)

- **Internet Gateway**
  - This is created if the code base is creating the VPC and subnets  
    **NOTE:** If the customer is providing the VPC and subnets, it's their responsibility to provide connectivity similar to the gateway in this infrastructure

- **Route Tables**
  - These are created if the code base is creating the subnets  
    **NOTE:** If the customer is providing the subnets, it is their responsibility to provide route tables and routes for each of the subnets provided.  
    They must also provide connectivity that is sufficient for the infrastructure to communicate successfully between those subnets.
    - Public Route Table - Associated with the public subnet and VPC
      - Public Internet Gateway Route - Associated with the public route table and the internet gateway
        - The route allows all traffic: `0.0.0.0/0`
    - Private Route Table - Associated with the private subnet and VPC
    - Control Plane Route Table - Associated with the control plane subnet and VPC
    - Database Route Table - Associated with the database subnet and VPC

- **Elastic IP (NAT)**
  - This is created as the public endpoint of the cluster and is associated with the NAT Gateway unless a NAT is provided by the customer
  - This is not created if you have provided your VPC and subnets

- **NAT Gateway**
  - This is created if the code base is controlling the NAT ID

- **Private NAT Gateway**
  - This is created if the code base is controlling the NAT ID

---

## Security

[IAC Security Code](https://github.com/sassoftware/viya4-iac-aws/blob/main/security.tf)

The following [security groups](https://github.com/sassoftware/viya4-iac-aws/blob/main/docs/user/BYOnetwork.md#security-groups) will be created as outlined here.

The include rules, their Ports, protocols, and source groups

**NOTE:** When creating or having a BYO network scenario, one must consult with their Network Administrator and set up what's needed to configure a working AWS VPC network for the infrastructure.

- **AWS Security Group**
  - This is created if a security group is not provided 
  - It is an auxiliary security group associated with the RDS ENIs and VPC Endpoint ENIs as well as the Jump/NFS VM ENIs when they have public IPs
  - Security Group Egress rule:
    - Allow all outbound traffic from any protocol
  - Rules:
    - **VPC endpoints**
      - Creates an ingress rule for each VPC endpoint private access CIDR provided
        - Protocol: TCP
        - From: 443
        - To: 443
    - **VMs**
      - Create an ingress rule for each VM (jump, nfs)
        - Protocol: TCP
        - From: 22
        - To: 22
    - **Internal security group communication**
      - Allow all inbound traffic to the main security group
    - **Postgres Internal security group communication**
      - Allow inbound traffic from database to and from ports defined in each database
        - Protocol: TCP
    - **Postgres external security group communication**
      - Allow inbound traffic from the main security group to the external postgres server
        - Protocol: TCP

- **Cluster Security Group**
  - This is created if a security group is not provided
  - This is the EKS cluster's security group
  - Rules:
    - Create an egress rule for the cluster
      - Allow all outbound traffic from this security group
    - Create an ingress rule for all private endpoint access CIDRs
      - Protocol: TCP
      - From: 443
      - To: 443
    - Create an ingress rule for the cluster
      - This allows pods to communicate with EKS cluster API; connects the work security group with the cluster security group
      - Protocol: TCP
      - From: 443
      - To: 443

- **Workers Security Group**
  - This is created if a security group is not provided
  - This security group is for all work nodes in the cluster
  - Rules:
    - Create an egress rule for the workers
      - This allows cluster egress to the internet
      - Allow all outbound traffic from this security group 
    - Create an ingress rule for the workers
      - Allow communication between all worker security groups
    - Create a rule that allows traffic from the cluster security group to the worker security group
      - Protocol: TCP
      - From: 1025
      - To: 65535
    - Create a rule that allows the pods to talk with the control plane via the API server
      - Protocol: TCP
      - From: 443
      - To: 443
    - Create a rule that allows SSH to a private IP based Jump VM per the private access CIDRs provided
      - Protocol: TCP
      - From: 22
      - To: 22

---

## EKS

[IAC EKS Code](https://github.com/sassoftware/viya4-iac-aws/blob/main/main.tf#L94)

- A generic EKS cluster
- [Documentation](https://github.com/terraform-aws-modules/terraform-aws-eks)
- This repo configures several items including:
  - Cluster Security Group
  - Node Security Group
  - IAM Role Policies
  - EKS Managed Node Groups for both the default node group and the user defined node groups

---

## VMS

[IAC VMS Code](https://github.com/sassoftware/viya4-iac-aws/blob/main/vms.tf)

- Stand up VMs and supporting storage
- [Generic VM module](https://github.com/sassoftware/viya4-iac-aws/blob/main/modules/aws_vm/main.tf)
  - Jump VM
  - NFS Server

- Storage and initialization items:
  - [FSX OnTAP](https://github.com/sassoftware/viya4-iac-aws/blob/main/vms.tf#L19)
  - [EFS](https://github.com/sassoftware/viya4-iac-aws/blob/main/vms.tf#L60)
  - [Jump VM cloud-config](https://github.com/sassoftware/viya4-iac-aws/blob/main/vms.tf#L80)

---

Misc items needed for AWS and IAM rule setup for baseline items: Cluster Autoscaling, Metrics Server, EBS CSI Driver, FSX onTap

---

## PostgreSQL

[IAC PostgreSQL Code](https://github.com/sassoftware/viya4-iac-aws/blob/main/main.tf#L269)

- External database configured by default
- [Documentation](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/6.2.0)

---

## Resource Group

[IAC Resource Group Code](https://github.com/sassoftware/viya4-iac-aws/blob/main/main.tf#L327)

- Resource group made up of the current deployment's items
- [Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/resourcegroups_group.html)

---

## Modules

These modules are used to create IAM policies for use with standard Kubernetes cluster items:

- [Autoscaling](https://github.com/sassoftware/viya4-iac-aws/blob/main/modules/aws_autoscaling/main.tf)
- [EBS CSI](https://github.com/sassoftware/viya4-iac-aws/blob/main/modules/aws_ebs_csi/main.tf)
- [FSX onTap](https://github.com/sassoftware/viya4-iac-aws/blob/main/modules/aws_fsx_ontap/main.tf)
