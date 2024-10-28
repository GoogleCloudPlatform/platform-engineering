resource "google_storage_bucket" "function_bucket" {
  name = "${var.project_id}-gcf-source"
  location = "US"
  uniform_bucket_level_access = true 
}

data "archive_file" "createRelease" {
  type = "zip"
  output_path = "/tmp/function-createRelease.zip"
  source_dir = "CloudFunctions/createRelease/"
}

data "archive_file" "cloudDeployInteractions" {
  type = "zip"
  output_path = "/tmp/function-cloudDeployInteractions.zip"
  source_dir = "CloudFunctions/cloudDeployInteractions/"
}

data "archive_file" "cloudDeployOperations" {
  type = "zip"
  output_path = "/tmp/function-cloudDeployOperations.zip"
  source_dir = "CloudFunctions/cloudDeployOperations/"
}

data "archive_file" "cloudDeployApprovals" {
  type = "zip"
  output_path = "/tmp/function-cloudDeployApprovals.zip"
  source_dir = "CloudFunctions/cloudDeployApprovals/"
}

resource "google_storage_bucket_object" "createRelease" {
  name = "function-create-release.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.createRelease.output_path
}

resource "google_storage_bucket_object" "cloudDeployInteractions" {
  name = "function-cloudDeployInteractions.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.cloudDeployInteractions.output_path
}

resource "google_storage_bucket_object" "cloudDeployOperations" {
  name = "function-cloudDeployOperations.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.cloudDeployOperations.output_path
}

resource "google_storage_bucket_object" "cloudDeployApprovals" {
  name = "function-cloudDeployApprovals.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.cloudDeployApprovals.output_path
}

# Create a Cloud Function to trigger Cloud Deploy
resource "google_cloudfunctions2_function" "create-release" {
  name    = "create-release"
  project = var.project_id
  location = var.region
  build_config {
    entry_point = "deployTrigger"
    runtime     = "go122" # Or your preferred runtime
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name # Replace with your bucket name
        object = google_storage_bucket_object.createRelease.name # Replace with your source code object
      }
    }
  }

  service_config {
    all_traffic_on_latest_revision = true
    available_memory               = "256M" # Adjust as needed
    ingress_settings               = "ALLOW_ALL"
    timeout_seconds                = 60 # Adjust as needed
    environment_variables = {
      PROJECTID = "${var.project_id}"
      LOCATION = "${var.region}"
      PIPELINE = "${google_clouddeploy_delivery_pipeline.primary.name}"
      TRIGGER = "${google_cloudbuild_trigger.build-cloudrun-deploy.trigger_id}"
      SENDTOPICID = "${google_pubsub_topic.deploy-commands.name}"
    }
  }

  event_trigger {
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy = "RETRY_POLICY_RETRY"
    trigger_region = var.region
    pubsub_topic = google_pubsub_topic.build_notifications.id
  }

  depends_on = [ google_cloudbuild_trigger.build-cloudrun-deploy ]
}

# Create a Cloud Function to interact with Cloud Deploy
resource "google_cloudfunctions2_function" "cloudDeployInteractions" {
  name    = "cloud-deploy-interactions"
  project = var.project_id
  location = var.region

  build_config {
    entry_point = "cloudDeployInteractions"
    runtime     = "go122" # Or your preferred runtime
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name # Replace with your bucket name
        object = google_storage_bucket_object.cloudDeployInteractions.name # Replace with your source code object
      }
    }
  }

  service_config {
    all_traffic_on_latest_revision = true
    available_memory               = "256M" # Adjust as needed
    ingress_settings               = "ALLOW_ALL"
    timeout_seconds                = 60 # Adjust as needed
    environment_variables = {
      PROJECTID = "${var.project_id}"
      LOCATION = "${var.region}"
    }
  }

  event_trigger {
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy = "RETRY_POLICY_RETRY"
    trigger_region = var.region
    pubsub_topic = google_pubsub_topic.deploy-commands.id
  }
}

# Create a Cloud Function to interact with Cloud Deploy Operations
resource "google_cloudfunctions2_function" "cloudDeployOperations" {
  name    = "cloud-deploy-operations"
  project = var.project_id
  location = var.region

  build_config {
    entry_point = "cloudDeployOperations"
    runtime     = "go122" # Or your preferred runtime
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name # Replace with your bucket name
        object = google_storage_bucket_object.cloudDeployOperations.name # Replace with your source code object
      }
    }
  }

  service_config {
    all_traffic_on_latest_revision = true
    available_memory               = "256M" # Adjust as needed
    ingress_settings               = "ALLOW_ALL"
    timeout_seconds                = 60 # Adjust as needed
    environment_variables = {
      PROJECTID = "${var.project_id}"
      LOCATION = "${var.region}"
      SENDTOPICID = google_pubsub_topic.deploy-commands.name
    }
  }

  event_trigger {
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy = "RETRY_POLICY_RETRY"
    trigger_region = var.region
    pubsub_topic = google_pubsub_topic.deploy_operations.id
  }
}

# Create a Cloud Function to interact with Cloud Deploy Approvals
resource "google_cloudfunctions2_function" "cloudDeployApprovals" {
  name    = "cloud-deploy-approvals"
  project = var.project_id
  location = var.region

  build_config {
    entry_point = "cloudDeployApprovals"
    runtime     = "go122" # Or your preferred runtime
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name # Replace with your bucket name
        object = google_storage_bucket_object.cloudDeployApprovals.name # Replace with your source code object
      }
    }
  }

  service_config {
    all_traffic_on_latest_revision = true
    available_memory               = "256M" # Adjust as needed
    ingress_settings               = "ALLOW_ALL"
    timeout_seconds                = 60 # Adjust as needed
    environment_variables = {
      PROJECTID = "${var.project_id}"
      LOCATION = "${var.region}"
      SENDTOPICID = google_pubsub_topic.deploy-commands.name
    }
  }

  event_trigger {
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy = "RETRY_POLICY_RETRY"
    trigger_region = var.region
    pubsub_topic = google_pubsub_topic.deploy_approvals.id
  }
}