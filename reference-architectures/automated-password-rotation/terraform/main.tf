# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


data "google_project" "project" {
  project_id = var.project_id
}


resource "google_pubsub_schema" "avro_schema" {
  name = "my-avro-schema"
  type = "AVRO"
  definition = jsonencode({
    "type" : "record",
    "name" : "Avro",
    "fields" : [
      { "name" : "secretid", "type" : "string" },
      { "name" : "instance_name", "type" : "string" },
      { "name" : "db_user", "type" : "string" },
      { "name" : "db_name", "type" : "string" },
      { "name" : "db_location", "type" : "string" },
    ]
  })
  depends_on = [
    google_project_service.services
  ]
}

resource "google_pubsub_topic" "pubsub_topic" {
  name = "pswd-rotation-topic"
  schema_settings {
    schema   = google_pubsub_schema.avro_schema.id
    encoding = "JSON"
  }
  depends_on = [
    google_project_service.services
  ]
}


resource "google_service_account" "scheduler_account" {
  project      = var.project_id
  account_id   = var.scheduler_sa
  display_name = "Cloud Scheduler Service Account for password rotation"
  depends_on = [
    google_project_service.services
  ]
}

resource "google_service_account" "function_account" {
  project      = var.project_id
  account_id   = var.function_sa
  display_name = "Cloud Function Service Account for password rotation"
  depends_on = [
    google_project_service.services
  ]
}

resource "google_cloud_scheduler_job" "scheduler" {
  name        = var.scheduler_name
  description = "Publishes password rotation message on 1st day of the month"
  schedule    = "0 0 1 * *" // Run at midnight on the 1st of the month
  time_zone   = "America/New_York"

  pubsub_target {
    topic_name = google_pubsub_topic.pubsub_topic.id
    data       = base64encode(jsonencode({ "secretid" : split("/", "${google_secret_manager_secret.cloudsql_pswd.id}")[3], "instance_name" : "${var.instance_name}", "db_user" : "${var.db_user}", "db_name" : "${var.db_name}", "db_location" : "${var.region}" }))
  }
  retry_config {
    min_backoff_duration = "5s"
    max_backoff_duration = "3600s"
    max_retry_duration   = "0s"
    max_doublings        = 5
    retry_count          = 0
  }
  depends_on = [
    google_project_service.services
  ]

}

// Grant the scheduler permission to publish to the topic

resource "google_pubsub_topic_iam_binding" "scheduler_publisher" {
  topic = google_pubsub_topic.pubsub_topic.name
  role  = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.scheduler_account.email}",
  ]
  depends_on = [
    google_project_service.services
  ]
}

// Create GCS for storing function code
resource "google_storage_bucket" "function_bucket" {
  name     = "pswd-rotation-code-${var.project_id}"
  location = var.region
  project  = var.project_id
}

// permisison the Cloud function SA to read the bucket
resource "google_storage_bucket_iam_member" "read_bucket" {
  bucket     = google_storage_bucket.function_bucket.name
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${google_service_account.function_account.email}"
  depends_on = [google_storage_bucket.function_bucket, google_project_service.services]

}

// permisison the Cloud function SA to to work with CloudSql
resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.function_account.email}"
  depends_on = [
    google_project_service.services
  ]
}


// Generates an archive of the source code compressed as a .zip file.
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "/tmp/function.zip"
}

// Add source code zip to the Cloud Function's bucket
resource "google_storage_bucket_object" "zip" {
  source       = data.archive_file.source.output_path
  content_type = "application/zip"

  # Append to the MD5 checksum of the file's content
  # to force the zip to be updated as soon as a change occurs
  name   = "src-${data.archive_file.source.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name

  depends_on = [
    google_storage_bucket.function_bucket,
    data.archive_file.source
  ]
}

//Creating a secretmanager to store the db password
resource "random_password" "pass-webhook" {
  length  = 10
  special = false
}

resource "google_secret_manager_secret" "cloudsql_pswd" {
  secret_id = "cloudsql-pswd"
  replication {
    auto {}
  }
  project = var.project_id
  depends_on = [
    google_project_service.services
  ]
}

resource "google_secret_manager_secret_version" "cloudsql_pswd_secret" {
  secret      = google_secret_manager_secret.cloudsql_pswd.id
  secret_data = random_password.pass-webhook.result
}

resource "google_secret_manager_secret_iam_member" "cloudsql_pswd_secret_access" {
  secret_id = google_secret_manager_secret.cloudsql_pswd.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
  depends_on = [
    google_project_service.services
  ]
}

resource "google_secret_manager_secret_iam_member" "cloudsql_pswd_secret_write" {
  secret_id = google_secret_manager_secret.cloudsql_pswd.id
  role      = "roles/secretmanager.secretVersionAdder"
  member    = "serviceAccount:${google_service_account.function_account.email}"
  depends_on = [
    google_project_service.services
  ]
}

// Grant access to scheduler SA to invoke run for 2nd gen Cloud Function
resource "google_project_iam_member" "scheduler_runinvoke" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_account.email}"
  depends_on = [
    google_project_service.services
  ]
}



//Have to enable cloudresourcemanager & serviceusage.googleapis.com API before running TF

resource "google_project_service" "services" {
  for_each                   = toset(var.services)
  service                    = each.value
  disable_dependent_services = true
}

//Creating Serverless VPC connector to connect from Cloud Function to CloudSQL over private IP
resource "google_vpc_access_connector" "cloudsql_connector" {
  provider       = google
  name           = var.connector_name
  project        = var.project_id
  region         = var.region
  ip_cidr_range  = var.connector_cidr
  network        = var.vpc_network
  machine_type   = var.connector_machine_type
  min_throughput = 200
  max_throughput = 800
  depends_on = [
    google_project_service.services
  ]
}
// Setting up VPC peering for private IP access of the CloudSql instance
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "projects/${var.project_id}/global/networks/${var.vpc_network}"
  depends_on = [
    google_project_service.services
  ]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = "projects/${var.project_id}/global/networks/${var.vpc_network}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on = [
    google_project_service.services
  ]
  provider = google-beta
}

// Creating CloudSql
resource "google_sql_database" "test_db" {
  name     = var.db_name
  instance = google_sql_database_instance.cloudsql_instance.name
}
resource "google_sql_database_instance" "cloudsql_instance" {
  name             = var.instance_name
  database_version = var.database_version
  depends_on       = [google_vpc_access_connector.cloudsql_connector, google_project_service.services, google_service_networking_connection.private_vpc_connection]
  settings {
    tier              = var.db_instance_tier
    availability_type = "REGIONAL"
    disk_size         = 10
    ip_configuration {
      private_network                               = "projects/${var.project_id}/global/networks/${var.vpc_network}"
      enable_private_path_for_google_cloud_services = true
      ipv4_enabled                                  = false
    }
  }
  deletion_protection = false # so that TF destroy is able to cleanup the instance
}
resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.cloudsql_instance.name
  password = random_password.pass-webhook.result
}

// Cloud Function
resource "google_cloudfunctions2_function" "pubsub_handler" {
  name        = "pswd_rotator_function"
  description = "Handles Pub/Sub messages to rotate cloudsql password"
  build_config {
    runtime     = "python310"
    entry_point = "password_rotation_function" # Set the entry point
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.zip.name
      }
    }
  }
  service_config {
    max_instance_count    = 100
    min_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    vpc_connector         = google_vpc_access_connector.cloudsql_connector.id
    service_account_email = google_service_account.function_account.email
  }
  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.pubsub_topic.id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.scheduler_account.email
  }
  location = var.region
  depends_on = [
    google_project_service.services
  ]
}

// Miscellaneous
// Deploying a Cloud Function runs CloudBuild. The default service account for CloudBuild is the default Compute Engine service account. We need provide the following permission Compte Engine SA so it can deploy the Cloud Function successfully.

resource "google_project_iam_member" "ce_sa_permission" {
  for_each = toset(var.ce_sa_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    google_project_service.services
  ]
}
