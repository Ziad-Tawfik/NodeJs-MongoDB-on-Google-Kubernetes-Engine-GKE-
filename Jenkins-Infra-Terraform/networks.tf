# VPC
resource "google_compute_network" "vpc_network" {
  name                    = "gcp-final-proj-vpc"
  description             = "VPC for GCP final Project"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  depends_on              = [time_sleep.wait_project_init]
}


# SUBNETS
resource "google_compute_subnetwork" "subnet" {
  name                     = var.subnet_name
  ip_cidr_range            = var.cidr
  region                   = var.subnet_region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
  depends_on               = [google_compute_network.vpc_network]
}


# Jenkins Firewall
resource "google_compute_firewall" "allow_jenkins_ingress" {
  name    = "allow-jenkins-ingress-tf"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }
  direction = "INGRESS"
  # Add your ip instead of 0.0.0.0/0 to restrict access
  # for more security
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jenkins-vm"]
}