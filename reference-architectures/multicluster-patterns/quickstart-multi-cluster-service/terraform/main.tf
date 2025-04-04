/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
data "google_project" "project" {}

# Create a VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_1" {
  name          = "${var.vpc_name}-subnet-1"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet_2" {
  name          = "${var.vpc_name}-subnet-2"
  ip_cidr_range = "10.10.16.0/20"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_container_cluster" "cluster_1" {
  name               = "zonal-cluster-1"
  location           = var.zone_1
  network            = google_compute_network.vpc.id
  subnetwork         = google_compute_subnetwork.subnet_1.name
  initial_node_count = 3
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  workload_identity_config {
    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }
  fleet {
    project = var.project_id
  }
  deletion_protection = false
}

resource "google_container_cluster" "cluster_2" {
  name               = "zonal-cluster-2"
  location           = var.zone_2
  network            = google_compute_network.vpc.id
  subnetwork         = google_compute_subnetwork.subnet_2.name
  initial_node_count = 3
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  workload_identity_config {
    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }
  fleet {
    project = var.project_id
  }
  deletion_protection = false
}
