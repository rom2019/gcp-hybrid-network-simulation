#!/bin/bash

echo "=== Testing Terraform Configuration ==="
echo

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi

# Validate the configuration
echo "1. Validating Terraform configuration..."
terraform validate
if [ $? -eq 0 ]; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration has errors"
    exit 1
fi
echo

# Check for the required changes
echo "2. Checking for shielded VM configuration in compute.tf..."
if grep -q "shielded_instance_config" compute.tf; then
    echo "✅ Shielded VM configuration found"
    grep -A 5 "shielded_instance_config" compute.tf | sed 's/^/   /'
else
    echo "❌ Shielded VM configuration not found"
fi
echo

echo "3. Checking for external IP removal..."
if grep -q "access_config" compute.tf; then
    echo "❌ External IP configuration still present"
else
    echo "✅ External IP configuration removed"
fi
echo

echo "4. Checking for IAP SSH tag..."
if grep -q "iap-ssh" compute.tf; then
    echo "✅ IAP SSH tag found"
else
    echo "❌ IAP SSH tag not found"
fi
echo

echo "5. Checking for IAP firewall rule..."
if grep -q "dev-allow-iap-ssh" firewall.tf; then
    echo "✅ IAP firewall rule found"
    grep -A 10 "dev-allow-iap-ssh" firewall.tf | grep "source_ranges" | sed 's/^/   /'
else
    echo "❌ IAP firewall rule not found"
fi
echo

echo "6. Checking for user_email variable..."
if grep -q "user_email" variables.tf; then
    echo "✅ user_email variable defined"
else
    echo "❌ user_email variable not defined"
fi
echo

# Plan the changes
echo "7. Running terraform plan to see what will change..."
echo "   (This will show you the changes before applying)"
echo
terraform plan -compact-warnings

echo
echo "=== Configuration Test Complete ==="
echo
echo "Next steps:"
echo "1. Add 'user_email = \"your-email@example.com\"' to terraform.tfvars"
echo "2. Run 'terraform apply' to apply the changes"
echo "3. SSH using: gcloud compute ssh dev-workstation --zone=us-central1-a --project=<project-id> --tunnel-through-iap"