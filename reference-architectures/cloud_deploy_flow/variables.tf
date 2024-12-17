variable "project_id" {
  type = string
  description = "The Google Cloud project ID"
}

variable "region" {
  type = string
  description = "The preferred region for resources"
}

variable "github_owner" {
  type = string
  description = "Github Repo Owner"
}

variable "github_repo" {
  type = string
  description = "Github Repo"
}

locals {
  # Define a map of Pub/Sub topics and their respective subscription names
  pubsub_config = {
    "deploy-commands"        = "deploy-commands-subscription"
    "clouddeploy-operations" = "clouddeploy-operations-subscription"
    "clouddeploy-approvals"  = "clouddeploy-approvals-subscription"
    "cloud-builds"           = "build-notifications-subscription"
  }
  # List of services required
  gcp_service_list = [
    "pubsub.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com"
  ]
  # List of roles for Cloud Build SA
  sa_roles_list = [
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/storage.objectUser",
    "roles/clouddeploy.jobRunner",
    "roles/clouddeploy.releaser",
    "roles/run.developer",
    "roles/cloudbuild.builds.builder"
  ]
}