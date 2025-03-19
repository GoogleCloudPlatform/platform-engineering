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
 resource "google_container_cluster" "primary" {
  name               = var.cluster_1_name
  location           = var.region_1
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

  depends_on = [module.enabled_google_apis, google_compute_network.vpc_network]
}

resource "google_container_cluster" "secondary" {
  name               = var.cluster_2_name
  location           = var.region_2
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

  depends_on = [module.enabled_google_apis, google_compute_network.vpc_network]
}

resource "google_gke_hub_feature" "multiclusterservice" {
  name       = "multiclusterservicediscovery"
  location   = "global"
  project    = var.project_id
  depends_on = [module.enabled_google_apis, google_container_cluster.primary, google_container_cluster.secondary]
}



resource "google_gke_hub_feature" "multiclustergateway" {
  name       = "multiclusteringress"
  location   = "global"
  project    = var.project_id

  spec {
    multiclusteringress {
      config_membership = "projects/${var.project_id}/locations/${var.region_1}/memberships/${google_container_cluster.primary.name}"
    }
  }

  depends_on = [module.enabled_google_apis, google_container_cluster.primary, google_gke_hub_feature.multiclusterservice]
}

resource "google_artifact_registry_repository" "my-repo" {
  location      = var.region_1
  repository_id = "my-repository"
  description   = "Docker repository"
  format        = "DOCKER"
  depends_on    = [module.enabled_google_apis]
}

resource "google_clouddeploy_target" "primary_target" {
  location         = var.region_2
  name             = "primary-target"
  project          = var.project_id
  require_approval = true

  gke {
    cluster = google_container_cluster.primary.id
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
  }

  depends_on = [module.enabled_google_apis, google_container_cluster.primary]
}

resource "google_clouddeploy_target" "secondary_target" {
  location = var.region_2
  name     = "secondary-target"
  project  = var.project_id

  gke {
    cluster = google_container_cluster.secondary.id
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
  }

  depends_on = [module.enabled_google_apis, google_container_cluster.secondary]
}

resource "google_clouddeploy_target" "multi_target" {
  location         = var.region_1
  name             = "multi-target"
  project          = var.project_id
  require_approval = false

  multi_target {
    target_ids = [
      google_clouddeploy_target.secondary_target.target_id,
      google_clouddeploy_target.primary_target.target_id,
    ]
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    execution_timeout = "3600s"
  }

  depends_on = [module.enabled_google_apis, google_container_cluster.primary, google_container_cluster.secondary]
}

resource "google_clouddeploy_delivery_pipeline" "primary" {
  location    = var.region_1
  name        = "pipeline"
  description = "canary-delivery-pipeline"
  project     = var.project_id

  serial_pipeline {
    stages {
      profiles  = ["primary", "secondary"]
      target_id = google_clouddeploy_target.multi_target.target_id

      strategy {
        canary {
          canary_deployment {
            percentages = [25, 50, 75]
          }

          runtime_config {
            kubernetes {
              service_networking {
                deployment = "store"
                service    = "store"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [google_clouddeploy_target.multi_target]
}