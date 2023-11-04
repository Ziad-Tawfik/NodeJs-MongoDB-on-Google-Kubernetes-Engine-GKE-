provider "google" {
  # credentials = var.jsonkey
  project     = var.project
}

# Enable service Apis
resource "google_project_service" "gcp_services" {
  count                      = length(var.services)
  project                    = var.project
  service                    = var.services[count.index]
  disable_on_destroy         = var.dis_on_dest
  disable_dependent_services = false
}

# Wait for the new configuration to propagate
resource "time_sleep" "wait_project_init" {
  create_duration = "30s"
  depends_on      = [google_project_service.gcp_services]
}
