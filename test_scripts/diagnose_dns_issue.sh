#!/bin/bash

# Diagnostic script for Cloud DNS API issue

echo "=== DNS API Diagnostic Script ==="
echo "Timestamp: $(date)"
echo ""

# Get the actual project ID from the error message
PROJECT_ID="my-onprem-sim-088dfe15"

echo "1. Checking if Cloud DNS API is enabled for project: $PROJECT_ID"
gcloud services list --enabled --project="$PROJECT_ID" 2>/dev/null | grep -E "(dns|DNS)" || echo "   ❌ Cloud DNS API is NOT enabled"

echo ""
echo "2. Checking all enabled APIs for the project:"
gcloud services list --enabled --project="$PROJECT_ID" 2>/dev/null | head -10 || echo "   ⚠️  Unable to list APIs (might need authentication)"

echo ""
echo "3. Checking Terraform configuration for DNS resources:"
echo "   DNS resources found in iam.tf:"
grep -n "google_dns" iam.tf | head -5

echo ""
echo "4. Checking main.tf for DNS API enablement:"
grep -n "dns.googleapis.com" main.tf || echo "   ❌ DNS API enablement NOT found in main.tf"

echo ""
echo "5. APIs currently being enabled in main.tf:"
echo "   Dev project APIs:"
grep -A 10 "resource \"google_project_service\" \"dev_apis\"" main.tf | grep "googleapis.com" | sed 's/^/     /'

echo ""
echo "6. Terraform state check (if available):"
if [ -f terraform.tfstate ]; then
    echo "   Checking for DNS resources in state:"
    grep -c "google_dns" terraform.tfstate 2>/dev/null && echo "   ⚠️  DNS resources found in state file"
else
    echo "   No terraform.tfstate file found"
fi

echo ""
echo "=== DIAGNOSIS SUMMARY ==="
echo "The issue is that:"
echo "1. DNS resources (google_dns_managed_zone) are defined in iam.tf"
echo "2. But 'dns.googleapis.com' is NOT included in the API enablement list in main.tf"
echo "3. This causes Terraform to try creating DNS resources before the API is enabled"
echo ""
echo "SOLUTION: Add 'dns.googleapis.com' to the dev_apis list in main.tf"