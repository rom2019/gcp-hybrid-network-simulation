# firewall.tf - 방화벽 규칙

# Dev VPC 방화벽 규칙

# SSH 접속 허용 (Dev)
resource "google_compute_firewall" "dev_allow_ssh" {
  name    = "dev-allow-ssh"
  network = google_compute_network.dev_vpc.name
  project = google_project.dev_project.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = var.allowed_ssh_source_ranges
  target_tags   = ["ssh-allowed"]
}

# VPN 트래픽 허용 (Dev)
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

# 내부 통신 허용 (Dev)
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
    var.prod_subnet_cidr  # Prod 네트워크와의 통신 허용
  ]
}

# Health check 허용 (Dev)
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

# Prod VPC 방화벽 규칙

# VPN 트래픽 허용 (Prod)
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

# 내부 통신 허용 (Prod)
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
    var.dev_subnet_cidr  # Dev 네트워크와의 통신 허용
  ]
}

# Gemini API 접근 제한 (Prod)
resource "google_compute_firewall" "prod_restrict_api_access" {
  name    = "prod-restrict-api-access"
  network = google_compute_network.prod_vpc.name
  project = google_project.prod_project.project_id
  
  # HTTPS 트래픽만 허용
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  
  # Dev 네트워크에서만 접근 허용
  source_ranges = [var.dev_subnet_cidr]
  target_tags   = ["api-endpoint"]
  
  # 우선순위를 높게 설정하여 다른 규칙보다 먼저 적용
  priority = 100
}

# SSH 접속 차단 (Prod - 보안 강화)
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

# Health check 허용 (Prod)
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

# Google APIs 접근 허용 (양쪽 VPC)
resource "google_compute_firewall" "dev_allow_google_apis" {
  name    = "dev-allow-google-apis"
  network = google_compute_network.dev_vpc.name
  project = google_project.dev_project.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  
  destination_ranges = ["199.36.153.8/30"]  # restricted.googleapis.com
  priority           = 1000
}

resource "google_compute_firewall" "prod_allow_google_apis" {
  name    = "prod-allow-google-apis"
  network = google_compute_network.prod_vpc.name
  project = google_project.prod_project.project_id
  
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  
  destination_ranges = ["199.36.153.8/30"]  # restricted.googleapis.com
  priority           = 1000
}