UBUNTU Testing
# PIPELINE STIG & CIS for UBUNTU 18 & 20 TESTING
#
#
# George added this from his own repo
#
# To use this repo to create the testing environment
# Execute the following commands - terraform init, terrafrom plan, terrafrom apply -auto-approve

  ./startup.sh

# This will create the ec2, private key and host files for the test bed

# Install Ansible, Git and other's resouces on the newly created EC2
# The SSH command has a mode where you can run any single command on a remote server.

# Ubuntu18
  ssh -i Ubuntu-key.pem ubuntu@ec2-3-89-35-103.compute-1.amazonaws.com 'bash -s' < scripts/ubuntu-setup.sh

# Ubuntu20  
  ssh -i Ubuntu-key.pem ubuntu@ec2-3-95-13-227.compute-1.amazonaws.com 'bash -s' < scripts/ubuntu-setup.sh   

# Repeat for all EC2's that will be tested.

# ssh to the ec2 instances that you want to perform the testing

ssh -i Ubuntu-key.pem ubuntu@ec2-3-89-35-103.compute-1.amazonaws.com

# Git clone the repo from testing unto the EC2 Instance.

git clone https://github.com/ansible-lockdown/UBUNTU18-CIS.git

# Edit the site.yml to run on localhost

vi or nano UBUNTU18-CIS/site.yml

#
#
- hosts:  localhost

# Run the ansible-playbook against the localhost

ansible-playbook site.yml

# To get a listing of EC2 resouces within the project
terrafrom refresh 

# Examples
Outputs:

Ubuntu18 = "ssh -i Ubuntu-key.pem ubuntu@ec2-3-89-35-103.compute-1.amazonaws.com"
Ubuntu20 = "ssh -i Ubuntu-key.pem ubuntu@ec2-3-95-13-227.compute-1.amazonaws.com"
ec2_instance_ip_Ubuntu18 = "3.89.35.103"
ec2_instance_ip_Ubuntu20 = "3.95.13.227"

Welcome to your PIPELINE testing

# To clean up the testing environment
./cleanup.sh

# this will remove all EC2, Key name, hosts-dev, terraform state.

# NOTE: All terraform, git, ansible commands can be ran adhoc as well.
