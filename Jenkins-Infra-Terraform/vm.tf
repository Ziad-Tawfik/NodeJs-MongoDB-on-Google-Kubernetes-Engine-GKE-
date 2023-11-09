data "google_service_account" "tf_sa" {
  account_id = var.account_id
}

# Create management private VM
resource "google_compute_instance" "jenkins_vm" {
  name         = "jenkins-vm"
  machine_type = "e2-small"
  zone         = var.jenkins_vm_zone #"us-central1-a"

  # Attach the subnet
  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20231022"
      size  = 10
    }
  }

  service_account {
    email  = data.google_service_account.tf_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags                    = ["jenkins-vm"]
  metadata_startup_script = file("jenkins_vm_script.sh")
}