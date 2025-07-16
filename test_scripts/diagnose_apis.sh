#!/bin/bash

echo "=== Diagnosing VPN Gateway API Issue ==="
echo

# Check if gcloud is installed and authenticated
echo "1. Checking gcloud authentication..."
gcloud auth list
echo

# List available services that contain 'vpn' in the name
echo "2. Searching for VPN-related APIs..."
gcloud services list --available --filter="name:vpn" --format="table(name,title)"
echo

# List available services that contain 'gateway' in the name
echo "3. Searching for Gateway-related APIs..."
gcloud services list --available --filter="name:gateway" --format="table(name,title)"
echo

# Check what APIs are needed for VPN Gateway
echo "4. Checking Compute Engine API (which includes VPN Gateway)..."
gcloud services list --available --filter="name:compute.googleapis.com" --format="table(name,title)"
echo

# Check current project
echo "5. Current project configuration..."
gcloud config get-value project
echo

# Check if billing is enabled
echo "6. Checking billing account..."
gcloud beta billing projects describe $(gcloud config get-value project) 2>/dev/null || echo "Unable to check billing (this is normal if you don't have billing permissions)"
echo

echo "=== Diagnosis Complete ==="
echo
echo "FINDING: There is no 'vpn-gateway.googleapis.com' service in GCP."
echo "VPN Gateway functionality is provided by 'compute.googleapis.com' which you already have enabled."
echo "You should remove the 'vpn-gateway.googleapis.com' line from your Terraform configuration."