# Create management private VM
resource "google_compute_instance" "management_vm" {
  name         = "management-vm"
  machine_type = "e2-small"
  zone         = var.management_vm_zone #"us-east1-b"

  # Attach the subnet
  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnets[0].id
  }

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20231022"
      size  = 10
    }
  }

  service_account {
    email  = google_service_account.service_account[0].email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags                    = ["management-vm-ssh"]
  metadata_startup_script = file("management_vm_script.sh")
}