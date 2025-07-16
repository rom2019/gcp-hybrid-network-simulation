# VPN Troubleshooting Guide

## Current Issue
- Ping from Dev VM (10.0.1.2) to Prod subnet (10.1.1.2) is failing with 100% packet loss
- Terraform apply completed successfully
- Organization policy for VPN peer IPs has been updated

## Quick Checks

### 1. Run the diagnostic script
```bash
./diagnose_vpn_connectivity.sh
```

### 2. Check VPN Tunnel Status
The VPN tunnels should show "ESTABLISHED" status. If not:
- Verify the shared secret matches on both sides
- Check if the VPN gateways have been created successfully

### 3. Check BGP Session Status
BGP sessions should be in "Established" state. If not:
- Verify BGP peer IPs (169.254.0.1/30 and 169.254.1.1/30)
- Check ASN numbers (Dev: 64512, Prod: 64513)

### 4. Verify Routes
Check if routes are being advertised between VPCs:
```bash
# In Dev project
gcloud compute routes list --project=my-onprem-sim-088dfe15 | grep 10.1

# In Prod project  
gcloud compute routes list --project=my-gemini-prod-088dfe15 | grep 10.0
```

### 5. Test from VM
From the Dev VM, run these tests:
```bash
# Check routing table
ip route

# Traceroute to see where packets are dropping
traceroute 10.1.1.2

# Check if you can reach the VPN gateway
ping 169.254.0.2
```

## Common Solutions

### If VPN tunnels are not established:
1. Wait a few minutes for tunnels to establish
2. Check if all 4 tunnels are created (2 from each side)
3. Verify the VPN gateway IPs are reachable

### If BGP is not established:
1. Check Cloud Router configuration
2. Verify BGP peer configuration matches on both sides
3. Ensure router interfaces are properly configured

### If routes are missing:
1. Check BGP advertise mode is set to "CUSTOM"
2. Verify advertised IP ranges include the correct subnets
3. Ensure route priority is not blocking the routes

### If firewall is blocking:
The firewall rules look correct, but verify:
1. No higher priority deny rules
2. VM network tags if using tag-based rules
3. Implicit firewall rules aren't blocking

## Next Steps
1. Run the diagnostic script to get current status
2. Based on the output, follow the specific troubleshooting steps above
3. If VPN tunnels are established but BGP is not, focus on BGP configuration
4. If everything looks good but ping still fails, check VM-level routing and iptables