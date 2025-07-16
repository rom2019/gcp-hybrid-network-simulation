# dns.tf - Simplified DNS Configuration for Private Google API Access

# ------------------------------------------------------------------------------
# Dev Project DNS Configuration (on-prem-sim)
# ------------------------------------------------------------------------------
# All DNS configuration is now self-contained within the Dev project.
# The routing to reach the private IPs will be handled by BGP over the VPN.

# 1. Create a private DNS zone for googleapis.com in the Dev VPC
resource "google_dns_managed_zone" "googleapis_private_zone_in_dev" {
  project      = google_project.dev_project.project_id
  name         = "googleapis-private-zone"
  dns_name     = "googleapis.com."
  description  = "Private DNS zone for googleapis.com in the Dev VPC"
  visibility   = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.dev_vpc.self_link
    }
  }

  depends_on = [time_sleep.wait_for_apis]
}

# 2. Create A records for private.googleapis.com
resource "google_dns_record_set" "private_googleapis_a_record_in_dev" {
  project      = google_project.dev_project.project_id
  managed_zone = google_dns_managed_zone.googleapis_private_zone_in_dev.name
  name         = "private.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas      = [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11"
  ]
}

# 3. Create CNAME record to redirect all *.googleapis.com to private.googleapis.com
resource "google_dns_record_set" "googleapis_wildcard_cname_in_dev" {
  project      = google_project.dev_project.project_id
  managed_zone = google_dns_managed_zone.googleapis_private_zone_in_dev.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["private.googleapis.com."]
}

# ------------------------------------------------------------------------------
# Output DNS Configuration Information
# ------------------------------------------------------------------------------

output "dns_configuration_summary" {
  description = "Summary of the simplified DNS configuration"
  value = {
    private_zone_name = google_dns_managed_zone.googleapis_private_zone_in_dev.name
    private_zone_dns  = google_dns_managed_zone.googleapis_private_zone_in_dev.dns_name
    dns_location      = "Dev Project (on-prem-sim)"
    routing_method    = "BGP over VPN"
  }
}