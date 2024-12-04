# Configure the Google Cloud provider
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
  
  provider_meta "google" {
    module_name = "cloud-solutions/platform-engineering-cloud-deploy-pipeline-deploy-v1"
  }
}

# Ensure the project is created
data "google_project" "project" {
  project_id = var.project_id
}

# Enable Services
resource "google_project_service" "project" {
  for_each = toset(local.gcp_service_list)
  project = data.google_project.project.project_id
  service = each.key

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
  depends_on = [data.google_project.project]
}

# Create Pub/Sub topics using a for_each loop
resource "google_pubsub_topic" "topics" {
  for_each = local.pubsub_config

  name    = each.key
  project = data.google_project.project.project_id
}

# Create Pub/Sub subscriptions using a for_each loop, referencing the topics
resource "google_pubsub_subscription" "subscriptions" {
  for_each = local.pubsub_config

  name    = each.value
  topic   = google_pubsub_topic.topics[each.key].id
  project = data.google_project.project.project_id
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
  project = data.google_project.project.project_id
  location = var.region
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      # We add a dummy image here to get the service created
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
}

//Create CloudBuild SA
resource "google_service_account" "cloudbuild_service_account" {
  account_id   = "cloudbuild-sa"
  display_name = "cloudbuild-sa"
  description  = "Cloud build service account"
}

resource "google_project_iam_member" "act_as" {
  for_each = toset(local.sa_roles_list)
  project = data.google_project.project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

# Data source to get the default compute engine service account
data "google_compute_default_service_account" "default" {
  project = data.google_project.project.project_id
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
  name = "${data.google_project.project.project_id}-deploy-resources-bucket"
  location = "US"
  uniform_bucket_level_access = true 
  force_destroy = true
}



