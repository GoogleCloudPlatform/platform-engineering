resource "google_storage_bucket" "function_bucket" {
  name                       = "${data.google_project.project.project_id}-gcf-source"
  location                   = "US"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

locals {
  functions = {
    createRelease          = "CloudFunctions/createRelease/"
    cloudDeployInteractions = "CloudFunctions/cloudDeployInteractions/"
    cloudDeployOperations   = "CloudFunctions/cloudDeployOperations/"
    cloudDeployApprovals    = "CloudFunctions/cloudDeployApprovals/"
  }
}

# Create archive files and bucket objects using for_each
data "archive_file" "functions" {
  for_each    = local.functions
  type        = "zip"
  output_path = "/tmp/${each.key}.zip"
  source_dir  = each.value
}

resource "google_storage_bucket_object" "functions" {
  for_each = data.archive_file.functions
  name     = "${each.key}.zip"
  bucket   = google_storage_bucket.function_bucket.name
  source   = each.value.output_path
}

# Cloud Functions configuration map
locals {
  cloud_functions = {
    "create-release" = {
      entry_point = "deployTrigger"
      pubsub_topic = google_pubsub_topic.topics["cloud-builds"].id
    }
    "cloud-deploy-interactions" = {
      entry_point = "cloudDeployInteractions"
      pubsub_topic = google_pubsub_topic.topics["deploy-commands"].id
    }
    "cloud-deploy-operations" = {
      entry_point = "cloudDeployOperations"
      pubsub_topic = google_pubsub_topic.topics["clouddeploy-operations"].id
    }
    "cloud-deploy-approvals" = {
      entry_point = "cloudDeployApprovals"
      pubsub_topic = google_pubsub_topic.topics["clouddeploy-approvals"].id
    }
  }
}

# Create Cloud Functions using for_each
resource "google_cloudfunctions2_function" "functions" {
  for_each = local.cloud_functions

  name    = each.key
  project = data.google_project.project.project_id
  location = var.region

  build_config {
    entry_point      = each.value.entry_point
    runtime          = "go122"
    service_account  = google_service_account.cloudbuild_service_account.id
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.functions[each.key].name
      }
    }
  }

  service_config {
    all_traffic_on_latest_revision = true
    available_memory               = "256M"
    ingress_settings               = "ALLOW_ALL"
    timeout_seconds                = 60
    environment_variables = {
      PROJECTID   = data.google_project.project.project_id
      LOCATION    = var.region
      SENDTOPICID = google_pubsub_topic.topics["deploy-commands"].name
    }
  }

  event_trigger {
    event_type    = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy  = "RETRY_POLICY_RETRY"
    trigger_region = var.region
    pubsub_topic  = each.value.pubsub_topic
  }
}
