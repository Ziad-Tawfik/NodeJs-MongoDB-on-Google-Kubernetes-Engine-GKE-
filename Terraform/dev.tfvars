project = "gcp-project-402717"
artifact_repo_id = "final-project-repository"

services = [
  "cloudresourcemanager.googleapis.com", "iap.googleapis.com",
  "iam.googleapis.com", "compute.googleapis.com",
  "artifactregistry.googleapis.com", "container.googleapis.com",
  "networkconnectivity.googleapis.com", "cloudbuild.googleapis.com"
]
dis_on_dest = false

sa_acc_id = [
  "sa-man-vm-tf",
  "sa-gke-cls-tf"
]
sa_acc_desc = [
  "Service Account for management vm from tf",
  "Service Account for gke cluster from tf"
]

subnet_regions = ["us-east1", "us-east4"]
management_vm_zone = "us-east1-b"
subnet_names   = ["management-subnet", "workload-subnet"]
cidrs          = ["10.1.0.0/16", "10.2.0.0/16"]

management_roles = [
  "roles/artifactregistry.writer",
  "roles/container.admin",
  "roles/cloudbuild.builds.builder"
]

workload_roles = [
  "roles/artifactregistry.reader"
]
