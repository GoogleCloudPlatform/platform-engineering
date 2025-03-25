resource "google_artifact_registry_repository" "docker_repositories" {
  depends_on = [ google_project_service.required_apis ]
  project       = var.project_id
  location      = var.region
  repository_id = "main"
  labels        = var.labels
  description   = "my docker repository"
  format        = "DOCKER"
}