# vpn.tf - Cloud VPN 설정

# Dev VPN Gateway
resource "google_compute_ha_vpn_gateway" "dev_gateway" {
  name    = "dev-vpn-gateway"
  project = google_project.dev_project.project_id
  region  = var.region
  network = google_compute_network.dev_vpc.id
  
  depends_on = [google_compute_network.dev_vpc]
}

# Prod VPN Gateway
resource "google_compute_ha_vpn_gateway" "prod_gateway" {
  name    = "prod-vpn-gateway"
  project = google_project.prod_project.project_id
  region  = var.region
  network = google_compute_network.prod_vpc.id
  
  depends_on = [google_compute_network.prod_vpc]
}

# Dev Cloud Router (BGP용)
resource "google_compute_router" "dev_vpn_router" {
  name    = "dev-vpn-router"
  project = google_project.dev_project.project_id
  region  = var.region
  network = google_compute_network.dev_vpc.id
  
  bgp {
    asn               = 64512
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    
    advertised_ip_ranges {
      range = var.dev_subnet_cidr
    }
  }
}

# Prod Cloud Router (BGP용)
resource "google_compute_router" "prod_vpn_router" {
  name    = "prod-vpn-router"
  project = google_project.prod_project.project_id
  region  = var.region
  network = google_compute_network.prod_vpc.id
  
  bgp {
    asn               = 64513
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    
    advertised_ip_ranges {
      range = var.prod_subnet_cidr
      description = "Prod Subnet"
    }
    
    # Advertise the Private Google Access IP range to the on-prem network
    advertised_ip_ranges {
      range       = "199.36.153.8/30"
      description = "Private Google Access"
    }
  }
}

# VPN Tunnel 1 (Dev -> Prod)
resource "google_compute_vpn_tunnel" "dev_to_prod_tunnel1" {
  name                  = "dev-to-prod-tunnel1"
  project               = google_project.dev_project.project_id
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.dev_gateway.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.prod_gateway.id
  shared_secret         = var.vpn_shared_secret
  router                = google_compute_router.dev_vpn_router.id
  vpn_gateway_interface = 0
}

# VPN Tunnel 2 (Dev -> Prod) - HA를 위한 두 번째 터널
resource "google_compute_vpn_tunnel" "dev_to_prod_tunnel2" {
  name                  = "dev-to-prod-tunnel2"
  project               = google_project.dev_project.project_id
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.dev_gateway.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.prod_gateway.id
  shared_secret         = var.vpn_shared_secret
  router                = google_compute_router.dev_vpn_router.id
  vpn_gateway_interface = 1
}

# VPN Tunnel 1 (Prod -> Dev)
resource "google_compute_vpn_tunnel" "prod_to_dev_tunnel1" {
  name                  = "prod-to-dev-tunnel1"
  project               = google_project.prod_project.project_id
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.prod_gateway.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.dev_gateway.id
  shared_secret         = var.vpn_shared_secret
  router                = google_compute_router.prod_vpn_router.id
  vpn_gateway_interface = 0
}

# VPN Tunnel 2 (Prod -> Dev) - HA를 위한 두 번째 터널
resource "google_compute_vpn_tunnel" "prod_to_dev_tunnel2" {
  name                  = "prod-to-dev-tunnel2"
  project               = google_project.prod_project.project_id
  region                = var.region
  vpn_gateway           = google_compute_ha_vpn_gateway.prod_gateway.id
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.dev_gateway.id
  shared_secret         = var.vpn_shared_secret
  router                = google_compute_router.prod_vpn_router.id
  vpn_gateway_interface = 1
}

# BGP 세션 - Dev Router Interface 1
resource "google_compute_router_interface" "dev_router_interface1" {
  name       = "dev-router-interface1"
  router     = google_compute_router.dev_vpn_router.name
  region     = var.region
  project    = google_project.dev_project.project_id
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.dev_to_prod_tunnel1.name
}

# BGP 세션 - Dev Router Interface 2
resource "google_compute_router_interface" "dev_router_interface2" {
  name       = "dev-router-interface2"
  router     = google_compute_router.dev_vpn_router.name
  region     = var.region
  project    = google_project.dev_project.project_id
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.dev_to_prod_tunnel2.name
}

# BGP 세션 - Prod Router Interface 1
resource "google_compute_router_interface" "prod_router_interface1" {
  name       = "prod-router-interface1"
  router     = google_compute_router.prod_vpn_router.name
  region     = var.region
  project    = google_project.prod_project.project_id
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.prod_to_dev_tunnel1.name
}

# BGP 세션 - Prod Router Interface 2
resource "google_compute_router_interface" "prod_router_interface2" {
  name       = "prod-router-interface2"
  router     = google_compute_router.prod_vpn_router.name
  region     = var.region
  project    = google_project.prod_project.project_id
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.prod_to_dev_tunnel2.name
}

# BGP Peer - Dev to Prod 1
resource "google_compute_router_peer" "dev_bgp_peer1" {
  name                      = "dev-bgp-peer1"
  router                    = google_compute_router.dev_vpn_router.name
  region                    = var.region
  project                   = google_project.dev_project.project_id
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 64513
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.dev_router_interface1.name
}

# BGP Peer - Dev to Prod 2
resource "google_compute_router_peer" "dev_bgp_peer2" {
  name                      = "dev-bgp-peer2"
  router                    = google_compute_router.dev_vpn_router.name
  region                    = var.region
  project                   = google_project.dev_project.project_id
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64513
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.dev_router_interface2.name
}

# BGP Peer - Prod to Dev 1
resource "google_compute_router_peer" "prod_bgp_peer1" {
  name                      = "prod-bgp-peer1"
  router                    = google_compute_router.prod_vpn_router.name
  region                    = var.region
  project                   = google_project.prod_project.project_id
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.prod_router_interface1.name
}

# BGP Peer - Prod to Dev 2
resource "google_compute_router_peer" "prod_bgp_peer2" {
  name                      = "prod-bgp-peer2"
  router                    = google_compute_router.prod_vpn_router.name
  region                    = var.region
  project                   = google_project.prod_project.project_id
  peer_ip_address           = "169.254.1.1"
  peer_asn                  = 64512
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.prod_router_interface2.name
}