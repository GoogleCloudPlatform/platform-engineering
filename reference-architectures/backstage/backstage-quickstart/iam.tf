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

resource "google_service_account" "hostingSa" {
  project      = var.environment_project_id
  account_id   = var.hostingSaId
  display_name = var.hostingSaDisplayName
}

resource "google_project_iam_member" "repoReaderBinding" {
  project = var.environment_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.hostingSa.email}"
}

resource "google_project_iam_member" "logWriterBinding" {
  project = var.environment_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.hostingSa.email}"
}

resource "google_project_iam_member" "metricWriterBinding" {
  project = var.environment_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.hostingSa.email}"
}

resource "google_project_iam_member" "monitoringViewerBinding" {
  project = var.environment_project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.hostingSa.email}"
}

resource "google_project_iam_member" "metaDataWriterBinding" {
  project = var.environment_project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.hostingSa.email}"
}

resource "google_project_iam_member" "autoScalingMetricsWriterBinding" {
  project = var.environment_project_id
  role    = "roles/autoscaling.metricsWriter"
  member  = "serviceAccount:${google_service_account.hostingSa.email}"
}

resource "time_sleep" "wait_30_seconds" {
  create_duration = "30s"
}

resource "google_service_account_iam_policy" "workloadIdentity" {
  depends_on         = [google_container_cluster.hostingCluster, time_sleep.wait_30_seconds]
  service_account_id = google_service_account.workloadSa.name
  policy_data        = data.google_iam_policy.workloadIdentity.policy_data
}

data "google_iam_policy" "workloadIdentity" {
  binding {
    role = "roles/iam.workloadIdentityUser"

    members = [
      "serviceAccount:${var.environment_project_id}.svc.id.goog[backstage/ksa-backstage]"
    ]
  }
}

resource "google_service_account" "workloadSa" {
  project      = var.environment_project_id
  account_id   = var.workloadSaId
  display_name = var.workloadSaDisplayName
}

resource "google_project_iam_member" "cloudSqlBinding" {
  project = var.environment_project_id
  role    = "roles/cloudsql.editor"
  member  = "serviceAccount:${google_service_account.workloadSa.email}"
}

resource "google_project_iam_member" "cloudStorageBinding" {
  project = var.environment_project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.workloadSa.email}"
}

