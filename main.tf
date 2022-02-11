provider "aws" {
  region = "us-east-1"
}

variable "namespace" {
  type    = string
  default = "Ubuntu 18.04 & 20.04 Pipeline testing Environment"
}
# Defining Private Key
variable "private_key" {
  default = "Ubuntu-key.pem"
}


// Generate the SSH keypair that we’ll use to configure the EC2 instance.
// After that, write the private key to a local file and upload the public key to AWS

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "private_key" {
  filename          = "${path.module}/Ubuntu-key.pem"
  sensitive_content = tls_private_key.key.private_key_pem
  file_permission   = "0400"
}


resource "aws_key_pair" "key_pair" {
  key_name   = local_file.private_key.filename
  public_key = tls_private_key.key.public_key_openssh
}


// Create a security group with access to port 22 and port 80 open to serve HTTP traffic

data "aws_vpc" "default" {
  default = true
}


resource "aws_security_group" "allow_ssh" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.namespace
  }
}

resource "aws_instance" "Ubuntu18" {
  ami                         = "ami-0747bdcabd34c712a"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = aws_key_pair.key_pair.key_name
  tags = {
    Name = "${var.namespace}"
    Name = "UBUNTU18"
  }
# SSH into instance 
  connection {
    
    # Host name
    host = self.public_ip
    # The default username for our AMI
    user = "ubuntu"
    # Private key for connection
    private_key = file(pathexpand(var.private_key))
    # Type of connection
    type = "ssh"
  }

  provisioner "file" {
   source = "ansible_setup.sh"
   destination = "/home/ubuntu/ansible_setup.sh"       
 }

 provisioner "file" {
   source = "s3copy.sh"
   destination = "/home/ubuntu/s3copy.sh"       
 }

  provisioner "file" {
  source = "host-local-Ubuntu"
  destination = "/home/ubuntu/host-local-Ubuntu"      
 }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo chmod 755 ~/ansible_setup.sh",
      "sudo ~/ansible_setup.sh -i",
   ]
  }
}


resource "aws_instance" "Ubuntu20" {
  ami                         = "ami-09e67e426f25ce0d7"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = aws_key_pair.key_pair.key_name
  tags = {
    Name = "${var.namespace}"
    Name = "UBUNTU20"
  }

  # SSH into instance 
  connection {
    
    # Host name
    host = self.public_ip
    # The default username for our AMI
    user = "ubuntu"
    # Private key for connection
    private_key = file(pathexpand(var.private_key))
    # Type of connection
    type = "ssh"
  }
  
  provisioner "file" {
   source = "ansible_setup.sh"
   destination = "/home/ubuntu/ansible_setup.sh"      
 }
# If you place the CIS or STIG repo in the root directory it will be placed on remote ec2 during creation time.
#   provisioner "file" {
#    source = "UBUNTU20-CIS"
#    destination = "/home/ubuntu/UBUNTU20-CIS"       
#  }

 provisioner "file" {
   source = "s3copy.sh"
   destination = "/home/ubuntu/s3copy.sh"       
 }

  provisioner "file" {
  source = "host-local-Ubuntu"
  destination = "/home/ubuntu/host-local-Ubuntu"      
 }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo chmod 755 ~/ansible_setup.sh",
      "sudo ~/ansible_setup.sh -i",
      "sudo apt install awscli -y",
   ]
  }
}

// generate inventory file
resource "local_file" "inventory" {
  filename = "./hosts-ubuntu"
  content  = <<EOF
    # hosts-dev

    [SERVERS]
    Ubuntu18  ansible_host=${aws_instance.Ubuntu18.public_ip}
    Ubuntu20  anisble_hosts=${aws_instance.Ubuntu20.public_ip}
    debain10  anisble_hosts=${aws_instance.debian10.public_ip}

    [SERVERS.vars]
    setup_audit=true
    run_audit=true

    [local]
    control ansible_connection=local
    EOF
}

resource "aws_instance" "debian10" {
  ami                         = "ami-07d02ee1eeb0c996c"
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  key_name                    = aws_key_pair.key_pair.key_name
  tags = {
    Name = "${var.namespace}"
    Name = "debian10"
  }
  # SSH into instance 
  connection {
    
    # Host name
    host = self.public_ip
    # The default username for our AMI
    user = "admin"
    # Private key for connection
    private_key = file(pathexpand(var.private_key))
    # Type of connection
    type = "ssh"
  }
      
 provisioner "file" {
  source = "host-local-debian"
  destination = "/home/admin/host-local-debian"      
 }

}

// Output the public_ip and the Ansible command to connect to ec2 instance

output "ec2_instance_ip_Ubuntu18" {
  description = "IP address of the EC2 instance"
  value       = aws_instance.Ubuntu18.public_ip
}

output "Ubuntu18" {
  description = "Copy/Paste/Enter - You are in the IRD Testing Pipeline"
  value       = "ssh -i Ubuntu-key.pem ubuntu@${aws_instance.Ubuntu18.public_dns}"
}

output "ec2_instance_ip_Ubuntu20" {
  description = "IP address of the EC2 instance"
  value       = aws_instance.Ubuntu20.public_ip
}

output "Ubuntu20" {
  description = "Copy/Paste/Enter - You are in the IRD Testing Pipeline"
  value       = "ssh -i Ubuntu-key.pem ubuntu@${aws_instance.Ubuntu20.public_dns}"
}

output "ec2_instance_ip_debian10" {
  description = "IP address of the EC2 instance"
  value       = aws_instance.debian10.public_ip
}


output "debian10" {
  description = "Copy/Paste/Enter - You are in the IRD Testing Pipeline"
  value       = "ssh -i Ubuntu-key.pem admin@${aws_instance.debian10.public_dns}"
}


