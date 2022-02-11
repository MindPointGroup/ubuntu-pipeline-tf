#!/bin/bash

echo "Running terraform to delete VMs in AWS ..."
echo ""
terraform destroy -auto-approve
echo ""
echo "Done"
