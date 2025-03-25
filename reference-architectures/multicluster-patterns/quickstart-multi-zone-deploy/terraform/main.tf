/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
data "google_client_config" "default" {}
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)

}
resource "google_artifact_registry_repository" "my-repo" {
  location      = var.region
  project = var.project_id
  repository_id = "main"
  description   = "my docker repository"
  format        = "DOCKER"
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_1_name
  location           = var.zone_1
  initial_node_count = 3

  release_channel {
    channel = "RAPID"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  cost_management_config {
    enabled = true
  }

  fleet {
    project = var.project_id
  }

  deletion_protection = false

  resource_labels = {
    "config_cluster" = true
  }
}

resource "google_container_cluster" "secondary" {
  name               = var.cluster_2_name
  location           = var.zone_2
  initial_node_count = 3

  release_channel {
    channel = "RAPID"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  security_posture_config {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  cost_management_config {
    enabled = true
  }

  fleet {
    project = var.project_id
  }

  deletion_protection = false

  resource_labels = {
    "config_cluster" = false
  }
}

# GKE Hub Feature: Enable multicluster service discovery.
resource "google_gke_hub_feature" "multiclusterservice" {
  name     = "multiclusterservicediscovery"
  location = "global"
  project  = var.project_id
  depends_on = [
    google_container_cluster.primary,
    google_container_cluster.secondary
  ]
}

# GKE Hub Feature: Enable multicluster gateway (ingress).
resource "google_gke_hub_feature" "multiclustergateway" {
  name     = "multiclusteringress"
  location = "global"
  project  = var.project_id
  spec {
    multiclusteringress {
      config_membership = "projects/${var.project_id}/locations/${var.region}/memberships/${var.cluster_1_name}"
    }
  }
  depends_on = [
    google_container_cluster.primary,
    google_gke_hub_feature.multiclusterservice,
  ]
}

# Cloud Deploy Target: Define the primary target for deployments.
resource "google_clouddeploy_target" "primary_target" {
  location = var.region
  name     = "primary-target"
  project  = var.project_id
  labels = {
    "env" : "config"
  }
  gke {
    cluster = google_container_cluster.primary.id
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
  }
  depends_on = [google_container_cluster.primary]
}

# Cloud Deploy Target: Define the secondary target for deployments.
resource "google_clouddeploy_target" "secondary_target" {
  location = var.region
  name     = "secondary-target"
  project  = var.project_id
  gke {
    cluster = google_container_cluster.secondary.id
  }
  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
  }
  depends_on = [google_container_cluster.secondary]
}

# Cloud Deploy Delivery Pipeline: Define the delivery pipeline.
resource "google_clouddeploy_delivery_pipeline" "multi-cluster-pipeline" {
  location    = var.region
  name        = "multi-cluster-pipeline"
  description = "Delivery pipeline"
  project     = var.project_id
  serial_pipeline {
    stages {
      profiles  = ["config-cluster"]
      target_id = google_clouddeploy_target.primary_target.target_id
    }
    stages {
      profiles  = ["worker-cluster"]
      target_id = google_clouddeploy_target.secondary_target.target_id
    }
  }
}
