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

resource "google_container_cluster" "hostingCluster" {
  name       = var.hosting_cluster_name
  location   = var.region
  project    = var.environment_project_id
  network    = google_compute_network.backstageHostingVpc.self_link
  subnetwork = google_compute_subnetwork.backstageHostingNodeSubnet.self_link

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.hostingSa.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }


  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = true
    }
  }

  enable_autopilot = true
  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }
  deletion_protection = false

  secret_manager_config {
    enabled = true
  }

  master_authorized_networks_config {
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

}