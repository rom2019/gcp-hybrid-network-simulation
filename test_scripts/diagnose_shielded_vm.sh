#!/bin/bash

echo "=== Diagnosing Shielded VM and External IP Constraints ==="
echo

# Check organization policies
echo "1. Checking organization policies in the project..."
gcloud resource-manager org-policies list --project=$(gcloud config get-value project) 2>/dev/null | grep -E "(shieldedVm|ExternalIp)" || echo "No org policies found at project level"
echo

# Check if there's an organization associated
echo "2. Checking organization association..."
ORG_ID=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -1)
if [ -n "$ORG_ID" ]; then
    echo "Organization found: $ORG_ID"
    echo "Checking organization-level policies..."
    gcloud resource-manager org-policies list --organization=${ORG_ID##*/} 2>/dev/null | grep -E "(shieldedVm|ExternalIp)" || echo "No matching policies at org level"
else
    echo "No organization found or no access"
fi
echo

# Check current project constraints
echo "3. Checking effective policy constraints..."
PROJECT_ID=$(gcloud config get-value project)
echo "Project: $PROJECT_ID"
echo

# Check shielded VM constraint
echo "4. Checking compute.requireShieldedVm constraint..."
gcloud resource-manager org-policies describe compute.requireShieldedVm --project=$PROJECT_ID 2>/dev/null || echo "Policy not found at project level"
echo

# Check external IP constraint  
echo "5. Checking compute.vmExternalIpAccess constraint..."
gcloud resource-manager org-policies describe compute.vmExternalIpAccess --project=$PROJECT_ID 2>/dev/null || echo "Policy not found at project level"
echo

# Check if the image supports shielded VM
echo "6. Checking if debian-11 image supports shielded VM..."
gcloud compute images describe debian-11 --project=debian-cloud --format="value(shieldedInstanceInitialState)" 2>/dev/null || echo "Could not retrieve image info"
echo

echo "=== Diagnosis Complete ==="
echo
echo "Based on the Terraform error, you need to:"
echo "1. Add shielded_instance_config block with enable_secure_boot = true"
echo "2. Either remove the external IP or add the instance to the allowlist"