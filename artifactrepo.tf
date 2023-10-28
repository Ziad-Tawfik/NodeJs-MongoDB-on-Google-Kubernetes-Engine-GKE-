resource "google_artifact_registry_repository" "my_repository" {
  repository_id = var.artifact_repo_id #"final-project-repository"
  location      = var.subnet_regions[1]
  format        = "DOCKER"
}