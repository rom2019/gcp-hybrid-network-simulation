#!/bin/bash

echo "=== Detailed Policy Requirements Check ==="
echo

# Get the actual project ID from terraform
PROJECT_ID="my-onprem-sim-088dfe15"
echo "Checking policies for project: $PROJECT_ID"
echo

# Check if we need to switch project context
CURRENT_PROJECT=$(gcloud config get-value project)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "Switching to project $PROJECT_ID..."
    gcloud config set project $PROJECT_ID 2>/dev/null || echo "Could not switch to project"
fi

# Get detailed shielded VM policy
echo "1. Detailed shielded VM constraint:"
gcloud resource-manager org-policies describe compute.requireShieldedVm --project=$PROJECT_ID --format=json 2>/dev/null | jq '.' || echo "Could not get policy details"
echo

# Get detailed external IP policy
echo "2. Detailed external IP access constraint:"
gcloud resource-manager org-policies describe compute.vmExternalIpAccess --project=$PROJECT_ID --format=json 2>/dev/null | jq '.' || echo "Could not get policy details"
echo

# Check if there are any allowed values for external IP
echo "3. Checking for external IP allowlist:"
gcloud resource-manager org-policies describe compute.vmExternalIpAccess --project=$PROJECT_ID --format="value(spec.rules[].values.allowedValues[])" 2>/dev/null || echo "No allowlist found"
echo

# Switch back to original project if needed
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "Switching back to $CURRENT_PROJECT..."
    gcloud config set project $CURRENT_PROJECT 2>/dev/null
fi

echo "=== Policy Details Complete ==="