# Cloud DNS API Error - Diagnosis Report

## Problem Summary
Terraform is failing with error: `Cloud DNS API has not been used in project my-onprem-sim-088dfe15 before or it is disabled`

## Root Cause Analysis

### 1. **Primary Cause: Missing API Enablement**
   - ✅ **Confirmed**: Cloud DNS API (`dns.googleapis.com`) is NOT enabled for the project
   - ✅ **Confirmed**: DNS resources are defined in `iam.tf` (lines 130-168)
   - ✅ **Confirmed**: The API enablement list in `main.tf` does NOT include `dns.googleapis.com`

### 2. **Configuration Mismatch**
   - The `iam.tf` file creates:
     - `google_dns_managed_zone.googleapis` (line 130)
     - `google_dns_record_set.googleapis_a` (line 145)
     - `google_dns_record_set.googleapis_cname` (line 160)
   - But `main.tf` only enables these APIs for the dev project:
     - `compute.googleapis.com`
     - `cloudresourcemanager.googleapis.com`
     - `iam.googleapis.com`

### 3. **Other Potential Issues Ruled Out**
   - ❌ **Service account permissions**: Not the issue (would show different error)
   - ❌ **Project billing**: Billing is working (other APIs are enabled)
   - ❌ **Wrong project context**: Correct project is being used
   - ❌ **API propagation delay**: API was never enabled in the first place

## Evidence from Diagnostics
1. **API Status Check**: `gcloud services list` shows DNS API is not in the enabled list
2. **Configuration Check**: `grep` confirms DNS resources exist but API enablement is missing
3. **Currently Enabled APIs**: Only 5 APIs are enabled, DNS is not among them

## Solution
Add `dns.googleapis.com` to the `dev_apis` resource in `main.tf` at line 54:

```hcl
resource "google_project_service" "dev_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "dns.googleapis.com",  # Add this line
  ])
  
  project = google_project.dev_project.project_id
  service = each.key
  
  disable_on_destroy = false
}
```

## Why This Happened
The DNS resources were likely added to support Private Google Access (for routing googleapis.com traffic through private IPs), but the corresponding API enablement was forgotten in the main configuration.