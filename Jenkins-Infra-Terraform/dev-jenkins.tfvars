project    = "gcp-project-402717"
account_id = "sa-gcp-proj-tf"

services = [
  "cloudresourcemanager.googleapis.com", "iap.googleapis.com",
  "iam.googleapis.com", "compute.googleapis.com",
  "artifactregistry.googleapis.com", "container.googleapis.com",
  "networkconnectivity.googleapis.com", "cloudbuild.googleapis.com"
]
dis_on_dest = false

subnet_region   = "us-central1"
jenkins_vm_zone = "us-central1-a"
subnet_name     = "jenkins-subnet"
cidr            = "192.168.0.0/24"
