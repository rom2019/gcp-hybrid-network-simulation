# networks.tf - VPC 네트워크 구성

# Dev VPC (On-premises 시뮬레이션)
resource "google_compute_network" "dev_vpc" {
  name                    = "dev-vpc"
  project                 = google_project.dev_project.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  
  depends_on = [time_sleep.wait_for_apis]
}

# Dev Subnet
resource "google_compute_subnetwork" "dev_subnet" {
  name          = "dev-subnet"
  project       = google_project.dev_project.project_id
  network       = google_compute_network.dev_vpc.id
  ip_cidr_range = var.dev_subnet_cidr
  region        = var.region
  
  private_ip_google_access = false
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Prod VPC (Gemini API)
resource "google_compute_network" "prod_vpc" {
  name                    = "prod-vpc"
  project                 = google_project.prod_project.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  
  depends_on = [time_sleep.wait_for_apis]
}

# Prod Subnet
resource "google_compute_subnetwork" "prod_subnet" {
  name          = "prod-subnet"
  project       = google_project.prod_project.project_id
  network       = google_compute_network.prod_vpc.id
  ip_cidr_range = var.prod_subnet_cidr
  region        = var.region
  
  private_ip_google_access = false
  
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT for Dev VPC (인터넷 접속용)
#resource "google_compute_router" "dev_nat_router" {
#  name    = "dev-nat-router"
#  project = google_project.dev_project.project_id
#  network = google_compute_network.dev_vpc.id
#  region  = var.region
#}
#
#resource "google_compute_router_nat" "dev_nat" {
#  name                               = "dev-nat"
#  project                            = google_project.dev_project.project_id
#  router                             = google_compute_router.dev_nat_router.name
#  region                             = var.region
#  nat_ip_allocate_option             = "AUTO_ONLY"
#  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
#  
#  log_config {
#    enable = true
#    filter = "ERRORS_ONLY"
#  }
#}

# Cloud NAT for Prod VPC (필요시)
#resource "google_compute_router" "prod_nat_router" {
#  name    = "prod-nat-router"
#  project = google_project.prod_project.project_id
#  network = google_compute_network.prod_vpc.id
#  region  = var.region
#}
#
#resource "google_compute_router_nat" "prod_nat" {
#  name                               = "prod-nat"
#  project                            = google_project.prod_project.project_id
#  router                             = google_compute_router.prod_nat_router.name
#  region                             = var.region
#  nat_ip_allocate_option             = "AUTO_ONLY"
#  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
#  
#  log_config {
#    enable = true
#    filter = "ERRORS_ONLY"
#  }
#}
