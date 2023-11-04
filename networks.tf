# VPC
# resource "google_compute_network" "vpc_network" {
#   name                    = "gcp-final-proj-vpc"
#   description             = "VPC for GCP final Project"
#   auto_create_subnetworks = false
#   routing_mode            = "REGIONAL"
#   depends_on              = [time_sleep.wait_project_init]
# }

data "google_compute_network" "vpc_network" {
  name = "gcp-final-proj-vpc"
}

# SUBNETS
resource "google_compute_subnetwork" "subnets" {
  count                    = length(var.subnet_names)
  name                     = var.subnet_names[count.index]
  ip_cidr_range            = var.cidrs[count.index]
  region                   = var.subnet_regions[count.index]
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
  depends_on               = [google_compute_network.vpc_network]
}

# IAP Firewall
resource "google_compute_firewall" "allow_iap" {
  name    = "allow-iap-tf"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["management-vm-ssh"]
}