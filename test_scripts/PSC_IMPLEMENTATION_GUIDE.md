# Private Service Connect (PSC) Implementation Guide

This guide documents the implementation of Private Service Connect to restore Google API access for the dev-workstation VM after NAT deletion and Private Google Access being disabled.

## Problem Summary

The dev-workstation VM cannot access Google APIs (specifically AI Platform API) because:
- Cloud NAT has been deleted (commented out)
- Private Google Access is disabled in the dev VPC
- The VM has no external IP address
- Connection attempts to public Google API endpoints (199.36.153.10:443) fail

## Solution: Private Service Connect

Private Service Connect provides private connectivity to Google APIs without requiring:
- NAT Gateway
- External IP addressese
- Private Google Access
- Public internet connectivity

## Implementation Details

### 1. PSC Endpoints Created

Two PSC endpoints have been configured in `networks.tf`:

1. **All Google APIs Endpoint**
   - Internal IP: `10.0.1.100`
   - Service Attachment: Global attachment for all Google APIs
   - Provides access to all Google Cloud APIs

2. **AI Platform API Endpoint** 
   - Internal IP: `10.0.1.101`
   - Service Attachment: Regional attachment for Google APIs
   - Can be used for specific API access control

### 2. DNS Configuration

Private DNS zone configured to resolve Google APIs to PSC endpoints:
- Zone: `googleapis.com`
- Records:
  - `*.googleapis.com` → `10.0.1.100`
  - `aiplatform.googleapis.com` → `10.0.1.101`

### 3. Firewall Rules

Added firewall rule in `firewall.tf`:
- Rule: `dev-allow-psc-google-apis`
- Allows HTTPS (443) traffic to PSC endpoints
- Source: Dev subnet CIDR
- Destination: PSC endpoint IPs

## Applying the Changes

1. **Review the changes:**
   ```bash
   terraform plan
   ```

2. **Apply the configuration:**
   ```bash
   terraform apply
   ```

3. **Wait for resources to be created:**
   - PSC endpoints take 2-3 minutes to become active
   - DNS propagation may take additional 1-2 minutes

## Testing the Configuration

1. **SSH into the dev-workstation VM:**
   ```bash
   gcloud compute ssh dev-workstation \
     --project=<dev-project-id> \
     --zone=us-central1-a \
     --tunnel-through-iap
   ```

2. **Run the test script:**
   ```bash
   chmod +x /home/<user>/test_scripts/test_psc_connectivity.sh
   ./test_scripts/test_psc_connectivity.sh
   ```

3. **Manual testing:**
   ```bash
   # Test DNS resolution
   nslookup aiplatform.googleapis.com
   # Should resolve to 10.0.1.101

   # Test API connectivity
   curl -v https://aiplatform.googleapis.com
   
   # Test with authentication
   curl -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     "https://aiplatform.googleapis.com/v1/projects/$(gcloud config get-value project)/locations/global/publishers/google/models/gemini-2.0-flash:streamGenerateContent" \
     -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
   ```

## Troubleshooting

### DNS Not Resolving Correctly
- Check if the private DNS zone is active: `gcloud dns managed-zones list`
- Verify DNS records: `gcloud dns record-sets list --zone=googleapis-zone`
- Clear DNS cache on VM: `sudo systemctl restart systemd-resolved`

### Connection Timeouts
- Verify PSC endpoints are created: `gcloud compute forwarding-rules list`
- Check firewall rules: `gcloud compute firewall-rules list`
- Ensure the VM's metadata server can be reached: `curl -H "Metadata-Flavor: Google" http://metadata.google.internal`

### Authentication Issues
- Ensure service account has proper permissions
- Re-authenticate: `gcloud auth application-default login`
- Check project setting: `gcloud config get-value project`

## Benefits of PSC Approach

1. **Security**: Traffic never leaves Google's private network
2. **No Public Exposure**: VMs remain completely private
3. **Granular Control**: Can create specific endpoints for individual APIs
4. **Performance**: Lower latency through private connectivity
5. **Cost Effective**: No NAT gateway charges

## Alternative Solutions (Not Implemented)

1. **Enable Private Google Access**: Set `private_ip_google_access = true` in dev subnet
2. **Re-enable Cloud NAT**: Uncomment NAT configuration in `networks.tf`
3. **Add External IP**: Add public IP to VM (least secure)
4. **Route through Prod VPC**: Use VPN to route through Prod's Private Google Access

## References

- [Private Service Connect Documentation](https://cloud.google.com/vpc/docs/private-service-connect)
- [Configuring Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access)
- [Service Attachments for Google APIs](https://cloud.google.com/vpc/docs/about-accessing-google-apis-endpoints)