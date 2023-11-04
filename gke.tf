# Create private cluster
resource "google_container_cluster" "my-private-cluster" {
  name     = "dev-cluster"
  location = var.subnet_regions[1]

  # creating the least possible node pool  
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = data.google_compute_network.vpc_network.id
  subnetwork               = google_compute_subnetwork.subnets[1].id
  deletion_protection      = false

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.cidrs[0] #"10.1.0.0/16"
      display_name = "management-cidr"
    }
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
    master_global_access_config {
      enabled = true
    }
  }

  node_config {
    machine_type    = "e2-micro"
    service_account = google_service_account.service_account[1].email
    disk_size_gb    = 10
  }

}

resource "google_container_node_pool" "nodepool" {
  name       = "nodepool"
  location   = var.subnet_regions[1]
  cluster    = google_container_cluster.my-private-cluster.name
  node_count = 1

  node_config {
    machine_type = "e2-small"
    disk_size_gb = 20
    # Attach service account
    service_account = google_service_account.service_account[1].email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}