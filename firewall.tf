# firewall.tf - Firewall rules for Cloud IAP SSH access

# Allow SSH from Cloud IAP
resource "google_compute_firewall" "dev_allow_iap_ssh" {
  name    = "dev-allow-iap-ssh"
  network = google_compute_network.dev_vpc.name
  project = google_project.dev_project.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  # Cloud IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
  
  description = "Allow SSH access from Cloud IAP"
}

# Allow internal communication (Dev)
resource "google_compute_firewall" "dev_allow_internal" {
  name    = "dev-allow-internal"
  network = google_compute_network.dev_vpc.name
  project = google_project.dev_project.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [
    var.dev_subnet_cidr,
    var.prod_subnet_cidr  # Allow communication with Prod network
  ]
}

# VPN traffic (Dev)
resource "google_compute_firewall" "dev_allow_vpn" {
  name    = "dev-allow-vpn"
  network = google_compute_network.dev_vpc.name
  project = google_project.dev_project.project_id
  
  allow {
    protocol = "esp"
  }
  
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["vpn-allowed"]
}

# Health check (Dev)
resource "google_compute_firewall" "dev_allow_health_check" {
  name    = "dev-allow-health-check"
  network = google_compute_network.dev_vpc.name
  project = google_project.dev_project.project_id
  
  allow {
    protocol = "tcp"
  }
  
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["health-check-allowed"]
}

# Prod VPC firewall rules

# VPN traffic (Prod)
resource "google_compute_firewall" "prod_allow_vpn" {
  name    = "prod-allow-vpn"
  network = google_compute_network.prod_vpc.name
  project = google_project.prod_project.project_id
  
  allow {
    protocol = "esp"
  }
  
  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }
  
  source_ranges = ["0.0.0.0/0"]
}

# Internal communication (Prod)
resource "google_compute_firewall" "prod_allow_internal" {
  name    = "prod-allow-internal"
  network = google_compute_network.prod_vpc.name
  project = google_project.prod_project.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [
    var.prod_subnet_cidr,
    var.dev_subnet_cidr  # Allow communication with Dev network
  ]
}

# Restrict API access (Prod)
resource "google_compute_firewall" "prod_restrict_api_access" {
  name    = "prod-restrict-api-access"
  network = google_compute_network.prod_vpc.name
  project = google_project.prod_project.project_id
  
  # HTTPS traffic only
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  
  # Only from Dev network
  source_ranges = [var.dev_subnet_cidr]
  target_tags   = ["api-endpoint"]
  
  priority = 100
}

# Deny SSH (Prod - security hardening)
resource "google_compute_firewall" "prod_deny_ssh" {
  name    = "prod-deny-ssh"
  network = google_compute_network.prod_vpc.name
  project = google_project.prod_project.project_id
  
  deny {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = ["0.0.0.0/0"]
  priority      = 200
}

# Health check (Prod)
resource "google_compute_firewall" "prod_allow_health_check" {
  name    = "prod-allow-health-check"
  network = google_compute_network.prod_vpc.name
  project = google_project.prod_project.project_id
  
  allow {
    protocol = "tcp"
  }
  
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["health-check-allowed"]
}
