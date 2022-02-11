#!/bin/bash

echo "Running terraform to init workspaces..."
echo ""
terraform init
echo ""
echo " Passed Init, Next Plan TF"
terraform plan
echo""
echo "Passed planning, now apply auto-approve"
terraform apply -auto-approve
echo ""
echo "Welcome to your PIPELINE testing"
echo ""



