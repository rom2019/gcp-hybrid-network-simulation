# Cloud IAP SSH Access Instructions

## Changes Made to Fix the Terraform Errors

### 1. Fixed Shielded VM Configuration
Added the required `shielded_instance_config` block to the VM instance in `compute.tf`:
```hcl
shielded_instance_config {
  enable_secure_boot          = true
  enable_vtpm                 = true
  enable_integrity_monitoring = true
}
```

### 2. Removed External IP
Removed the `access_config` block from the network interface to comply with the organization policy that restricts external IP usage.

### 3. Added Cloud IAP Support
- Added `iap-ssh` tag to the VM instance
- Created firewall rule to allow SSH from Cloud IAP IP range (35.235.240.0/20)
- Added necessary IAM roles for Cloud IAP access

## How to SSH to the VM using Cloud IAP

1. First, add your email to `terraform.tfvars`:
```hcl
user_email = "your-email@example.com"
```

2. Apply the Terraform configuration:
```bash
terraform apply
```

3. SSH to the VM using Cloud IAP:
```bash
gcloud compute ssh dev-workstation \
  --zone=us-central1-a \
  --project=my-onprem-sim-088dfe15 \
  --tunnel-through-iap
```

## Alternative: Using IAP Desktop (Windows)
For Windows users, you can use IAP Desktop for a GUI-based SSH experience:
1. Download IAP Desktop from: https://github.com/GoogleCloudPlatform/iap-desktop/releases
2. Connect to your project
3. Double-click on the VM to connect via SSH

## Benefits of This Approach
- ✅ Complies with organization security policies
- ✅ No external IP required (more secure)
- ✅ Shielded VM with Secure Boot enabled
- ✅ Access is controlled via IAM permissions
- ✅ All SSH sessions are logged and auditable

## Troubleshooting
If you can't connect via IAP:
1. Ensure you have the `roles/iap.tunnelResourceAccessor` role
2. Check that the firewall rule for IAP is created
3. Verify the VM has the `iap-ssh` network tag
4. Make sure the IAP API is enabled in your project