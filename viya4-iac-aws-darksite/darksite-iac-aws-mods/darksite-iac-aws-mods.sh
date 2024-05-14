#!/bin/bash

## check that viya4-iac-aws/ exists in this folder
if [ ! -d "viya4-iac-aws/" ] 
then
  echo -e "\nError: Directory viya4-iac-aws/ does not exists!\n" 
  read -p "Would you like to locally clone the viya4-iac-aws github repo to fix (y/n)? " -n 1 -r REPLY
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
  ## Get IAC Version desired
  read -p "What release version of IAC do you want to use? " -r IAC_VERSION
  git clone --branch $IAC_VERSION https://github.com/sassoftware/viya4-iac-aws.git
fi

# mod to remove IGW and NAT GW?
echo
read -p "Would you like to mod local viya4-iac-aws clone to remove NAT and IGW (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  ## override file for viya4-iac-aws/modules/aws_vpc/
  tee viya4-iac-aws/modules/aws_vpc/main_override.tf > /dev/null <<EOF
## Override file to NOT deploy IGW and NAT GW
resource "aws_internet_gateway" "this" {
  count =  0
}

resource "aws_route" "public_internet_gateway" {
  count = 0
}

resource "aws_eip" "nat" {
  count = 0
}

data "aws_nat_gateway" "nat_gateway" {
  count = 0
}

resource "aws_nat_gateway" "nat_gateway" {
  count = 0
}

resource "aws_route" "private_nat_gateway" {
  count = 0
}
EOF

## override file for viya4-iac-aws/outputs.tf
tee viya4-iac-aws/outputs_override.tf > /dev/null <<EOF
## Override file to NOT deploy IGW and NAT GW
output "nat_ip" {
  value = null # no nat installed
}
EOF

  echo -e "\n+++Mod complete!"
fi

# mod to remove VPC Private Endpoints?
echo
read -p "Would you like to mod local viya4-iac-aws clone to remove deployment of VPC Private Endpoints (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "" >> viya4-iac-aws/modules/aws_vpc/main_override.tf
  echo 'resource "aws_vpc_endpoint" "private_endpoints" {' >> viya4-iac-aws/modules/aws_vpc/main_override.tf
  echo '  count = 0' >> viya4-iac-aws/modules/aws_vpc/main_override.tf
  echo '}' >> viya4-iac-aws/modules/aws_vpc/main_override.tf
  echo -e "\n+++Mod complete!"
fi

echo
read -p "Would you like to mod local viya4-iac-aws to add your custom AMI for jump and nfs servers (y/n)? " -n 1 -r REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -p "   What is the owner ID for the AMI? " -r OWNER_ID
  read -p "   What is the name of the AMI? " -r AMI_NAME
  tee viya4-iac-aws/modules/aws_vm/main.tf > /dev/null << EOF
# Reference: https://github.com/terraform-providers/terraform-provider-aws

# Hack for assigning disk in a vm based on an index value. 
locals {
  device_name = [
    # "/dev/sdb", - NOTE: These are skipped, Ubuntu Server 20.04 LTS
    # "/dev/sdc",         uses these for ephmeral storage.
    "/dev/sdd",
    "/dev/sde",
    "/dev/sdf",
    "/dev/sdg",
    "/dev/sdh",
    "/dev/sdi",
    "/dev/sdj",
    "/dev/sdk",
    "/dev/sdl",
    "/dev/sdm",
    "/dev/sdn",
    "/dev/sdo",
    "/dev/sdp",
    "/dev/sdq",
    "/dev/sdr",
    "/dev/sds",
    "/dev/sdt",
    "/dev/sdu",
    "/dev/sdv",
    "/dev/sdw",
    "/dev/sdx",
    "/dev/sdy",
    "/dev/sdz"
  ]
}

data "aws_ami" "ubuntu" {
  owners      = ["${OWNER_ID}"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["${AMI_NAME}"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "\${var.name}-admin"
  public_key = var.ssh_public_key
}

resource "aws_instance" "vm" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = var.vm_type
  user_data         = (var.cloud_init != "" ? var.cloud_init : null)
  key_name          = aws_key_pair.admin.key_name
  availability_zone = var.data_disk_availability_zone

  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.create_public_ip

  root_block_device {
    volume_type           = var.os_disk_type
    volume_size           = var.os_disk_size
    delete_on_termination = var.os_disk_delete_on_termination
    iops                  = var.os_disk_iops
    encrypted             = var.enable_ebs_encryption
  }

  tags = merge(var.tags, tomap({ Name : "\${var.name}-vm" }))

}

resource "aws_eip" "eip" {
  count    = var.create_public_ip ? 1 : 0
  vpc      = true
  instance = aws_instance.vm.id
  tags     = merge(var.tags, tomap({ Name : "\${var.name}-eip" }))
}

resource "aws_volume_attachment" "data-volume-attachment" {
  count       = var.data_disk_count
  device_name = element(local.device_name, count.index)
  instance_id = aws_instance.vm.id
  volume_id   = element(aws_ebs_volume.raid_disk.*.id, count.index)
}

resource "aws_ebs_volume" "raid_disk" {
  count             = var.data_disk_count
  availability_zone = var.data_disk_availability_zone
  size              = var.data_disk_size
  type              = var.data_disk_type
  iops              = var.data_disk_iops
  tags              = merge(var.tags, tomap({ Name : "\${var.name}-vm" }))
  encrypted         = var.enable_ebs_encryption
}
EOF
  tee viya4-iac-aws/files/cloud-init/nfs/cloud-config > /dev/null << EOF
#cloud-config
system_info:
  default_user:
    name: \${vm_admin}

#
# Wait for disks to be mounted then continue
#
bootcmd:
  - while [ `lsblk -frn | grep 'nvme' | grep -v 'nvme0' | wc -l` -lt 4 ]; do sleep 5; done

#
# First we'll update the repo and then update the OS.
#
package_update: false
package_upgrade: false

#
# Install packages
#
packages:
#  - nfs-kernel-server

#
# Create mount directories
#
runcmd:
  #
  # Create /export directory with the correct owner/permissions
  #
  - mkdir /export
  - chown nobody:nogroup /export -R
  - chmod -R 0777 /export
  #
  # Update systemctl services
  #
  - systemctl enable nfs-kernel-server
  - systemctl start nfs-kernel-server
  - systemctl enable rpc-statd
  - systemctl start rpc-statd
  #
  # Create Raid0 Array
  #
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/raid-config.html
  - mdadm --create --verbose /dev/md0 --level=0 --name=nfs-raid --raid-devices=4 $(lsblk -frnp | grep 'nvme' | grep -v 'nvme0' | xargs)
  - mkfs -t ext4 /dev/md0
  - mdadm --detail --scan | tee -a /etc/mdadm/mdadm.conf
  - update-initramfs -u
  # Update /etc/fstab
  #
  - device=`lsblk -r | grep raid0 | cut -d " " -f1`
  - mntDir='/export'
  - deviceUUID=`sudo blkid /dev/\$device | sed -r 's/.*UUID="([^"]*).*"/\1/g'`
  - echo "UUID=\$deviceUUID \$mntDir auto defaults,acl,nofail 0 2" | sudo tee -a /etc/fstab > /dev/null
  - mount -a
  #
  # Update /etc/exports
  #
  - for cidr_block in \${private_subnet_cidrs}
  - do
  -   echo "/export         \$cidr_block(rw,no_root_squash,async,insecure,fsid=0,crossmnt,no_subtree_check)" >> /etc/exports
  - done
  #
  # Restart nfs-server service
  #
  - exportfs -a
  - systemctl restart nfs-kernel-server
EOF
  tee viya4-iac-aws/files/cloud-init/jump/cloud-config > /dev/null << EOF
#cloud-config
system_info:
  default_user:
    name: \${vm_admin}

#
# First we'll update the repo and then update the OS.
#
package_update: false
package_upgrade: false

#
# Install packages
#
packages:
#  - nfs-common

#
# Update /etc/fstab
#
mounts:
  - \${mounts}

#
# Add nfs mounts
#
runcmd:
  - if ! [ -z "\${rwx_filestore_endpoint}" ]
  - then
      #
      # mount the nfs
      #
  -   while [ `df -h | grep "\${rwx_filestore_endpoint}:\${rwx_filestore_path}" | wc -l` -eq 0 ]; do sleep 5 && mount -a ; done
      # Create pvs folder and adjust perms and owner only if the folder doesn't exist
  -   if ! [ -d "\${jump_rwx_filestore_path}/pvs" ]
  -   then
        #
        # Change permissions and owner
        #
  -     mkdir -p \${jump_rwx_filestore_path}/pvs
  -     chmod 777 \${jump_rwx_filestore_path} -R
  -     chown -R nobody:nogroup \${jump_rwx_filestore_path}
  -   fi
  - fi
EOF
fi


# build modded viya4-iac-aws docker container?
echo
read -p "Would you like to build the modded viya4-iac-aws docker container (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "   What tag would you like to use for the modded container? " -r TAG
    docker build -t viya4-iac-aws:$TAG viya4-iac-aws/
    echo -e "\n+++Modded docker container is: viya4-iac-aws:${TAG}"
fi


# push modded docker container to ECR
echo
read -p "Would you like to push the viya4-iac-aws:${TAG} docker container to ECR (y/n)? " -n 1 -r REPLY
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

read -p "   What is your aws region? " -r AWS_REGION
read -p "   What is your aws acct ID? " -r AWS_ACCT_ID

aws ecr create-repository --no-cli-pager --repository-name viya4-iac-aws

docker tag viya4-iac-aws:$TAG $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/viya4-iac-aws:$TAG

aws ecr get-login-password --no-cli-pager --region $AWS_REGION | $DOCKER_SUDO docker login --username AWS --password-stdin $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker push $AWS_ACCT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/viya4-iac-aws:$TAG