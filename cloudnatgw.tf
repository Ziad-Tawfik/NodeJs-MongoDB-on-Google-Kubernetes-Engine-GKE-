# Create Router
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.vpc_network.id
  region  = google_compute_subnetwork.subnets[0].region
}

# Create Cloud Nat
resource "google_compute_router_nat" "nat_config" {
  name   = "nat-config"
  router = google_compute_router.nat_router.name
  region = google_compute_subnetwork.subnets[0].region

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.subnets[0].id
    source_ip_ranges_to_nat = [var.cidrs[0]]
  }
}