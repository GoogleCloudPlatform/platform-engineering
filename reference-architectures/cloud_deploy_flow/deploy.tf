# Assign Cloud Deploy Admin role to the default service account
resource "google_project_iam_member" "cloud_deploy_admin_binding" {
  project = var.project_id
  role    = "roles/clouddeploy.admin"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Assign Cloud Deploy Releaser role to the default service account
resource "google_project_iam_member" "cloud_deploy_releaser" {
  project = var.project_id
  role    = "roles/clouddeploy.releaser"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

# Grant "Service Account User" role to the default Compute Engine service account on the Cloud Build service account
# Required for Cloud Functions to handle releases (Maybe? Probably isn't needed)
resource "google_service_account_iam_binding" "allow_compute_sa_to_act_as" {
  service_account_id = google_service_account.cloudbuild_service_account.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${data.google_compute_default_service_account.default.email}",
  ]
}

# Create a Cloud Deploy pipeline
resource "google_clouddeploy_delivery_pipeline" "primary" {
  name        = "random-date-service"
  project = var.project_id
  location    = var.region
  description = "Pipeline triggered by JIRA notifications"

  serial_pipeline {
    stages {
      target_id = google_clouddeploy_target.primary.name
      #profiles = ["example-profile"] 
    }
  }
}

# Create a Cloud Deploy target
resource "google_clouddeploy_target" "primary" {
  # TODO(Ghaun): Figure out how to set Cloud Run Service name via Terraform
  # Currently had to set the delivery pipeline and target to the service name to make it work
  name     = "random-date-service"
  project = var.project_id
  location = "us-central1"
  #location = var.region
  require_approval = true # Set to true if you want manual approval for deployments

  # Configure Service Account 
  execution_configs {
    usages = ["RENDER", "DEPLOY"]
    service_account = "${google_service_account.cloudbuild_service_account.email}"
  }
  # Configure your deployment target (Cloud Run)
  run {
    location = "projects/${var.project_id}/locations/${var.region}"
  }
  depends_on = [ google_cloud_run_v2_service.main ]
}