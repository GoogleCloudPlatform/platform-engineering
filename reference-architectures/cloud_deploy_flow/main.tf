# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

variable "gcp_service_list" {
  description = "List of GCP Services to enable (WIP)"
  type = list(string)
  default = [
    "pubsub.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

# Enable Services (Work in Progress)
resource "google_project_service" "project" {
  for_each = toset(var.gcp_service_list)
  project = var.project_id
  service = each.key

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}

# Create a Pub/Sub topic for commands sent to CF to interact with Cloud Deploy
resource "google_pubsub_topic" "deploy-commands" {
  name = "deploy-commands"
  project = var.project_id
}

# Create a Pub/Sub subscription for deploy-commands topic
resource "google_pubsub_subscription" "deploy_commands_subscription" {
  name  = "deploy-commands-subscription"
  topic = google_pubsub_topic.deploy-commands.id
  project = var.project_id
}

# Create a Pub/Sub topic to receive Cloud Deploy Operations Notifications
resource "google_pubsub_topic" "deploy_operations" {
  name = "clouddeploy-operations"
  project = var.project_id
}

# Create a Pub/Sub subscription for clouddeploy-operations topic
resource "google_pubsub_subscription" "deploy_operations_subscription" {
  name  = "clouddeploy-operations-subscription"
  topic = google_pubsub_topic.deploy_operations.id
  project = var.project_id
}

resource "google_pubsub_topic" "deploy_approvals" {
  name = "clouddeploy-approvals"
  project = var.project_id
}

# Create a Pub/Sub subscription for clouddeploy-approvals topic
resource "google_pubsub_subscription" "deploy_approvals_subscription" {
  name  = "clouddeploy-approvals-subscription"
  topic = google_pubsub_topic.deploy_approvals.id
  project = var.project_id
}

# Create a Pub/Sub topic to receive Cloud Build Notifications
resource "google_pubsub_topic" "build_notifications" {
  name = "cloud-builds"
  project = var.project_id
}

# Create a Pub/Sub subscription for clouddeploy-approvals topic
resource "google_pubsub_subscription" "build_notifications_subscription" {
  name  = "build_notifications_subscription"
  topic = google_pubsub_topic.build_notifications.id
  project = var.project_id
}

# Create a repo inside Artifact Registry to store container images
resource "google_artifact_registry_repository" "random-date-app" {
  location      = "us-central1"
  repository_id = "random-date-app"
  description   = "Docker repo for random-date-app"
  format        = "DOCKER"
}


# Create a Cloud Run service (Random Date Service)
resource "google_cloud_run_v2_service" "main" {
  name     = "random-date-service"
  project = var.project_id
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      # We add a dummy image here to get the service created
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
}

variable "sa_roles_list" {
  description = "List of roles for Cloud Build SA"
  type = list(string)
  default = [
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/storage.objectUser",
    "roles/clouddeploy.jobRunner",
    "roles/clouddeploy.releaser",
    "roles/run.developer"
  ]
}

//Create CloudBuild SA
resource "google_service_account" "cloudbuild_service_account" {
  account_id   = "cloudbuild-sa"
  display_name = "cloudbuild-sa"
  description  = "Cloud build service account"
}

resource "google_project_iam_member" "act_as" {
  for_each = toset(var.sa_roles_list)
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

# Data source to get the default compute engine service account
data "google_compute_default_service_account" "default" {
  project = var.project_id
}


#This isn't perfect because you have to connect the repo first
#Not sure how to do this in terraform yet TODO: @Ghaun
# Create a Cloud Build trigger
resource "google_cloudbuild_trigger" "build-cloudrun-deploy" {
  name        = "random-date-build-trigger"
  location = "global"
  service_account = google_service_account.cloudbuild_service_account.id
  github {
    owner = var.github_owner
    name = var.github_repo
    push {
      branch = "main"
    }
  }

  filename = "CloudBuild/buildCloudRun.yaml" # Path to your Cloud Build configuration file
  substitutions = {
    "_DEPLOY_GCS" = google_storage_bucket.deploy_resources_bucket.url
  }
}

resource "google_storage_bucket" "deploy_resources_bucket" {
  name = "${var.project_id}-deploy-resources-bucket"
  location = "US"
  uniform_bucket_level_access = true 
  force_destroy = true
}



