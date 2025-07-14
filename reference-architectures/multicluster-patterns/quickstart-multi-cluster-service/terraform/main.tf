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

# VPC
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

resource "google_compute_subnetwork" "proxy_only" {
  name          = "proxy-only-subnet"
  ip_cidr_range = "10.128.0.0/23"
  region        = var.region
  network       = google_compute_network.vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  project       = var.project_id
}

# Cluster 1
data "google_compute_default_service_account" "default" {}
resource "google_container_cluster" "gke_1" {
  name                = "gke-1"
  location            = var.zone_1
  network             = google_compute_network.vpc.id
  subnetwork          = google_compute_subnetwork.subnet_1.name
  initial_node_count  = 1
  deletion_protection = false
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  workload_identity_config {
    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }
  fleet {
    project = var.project_id
  }
  dns_config {
    cluster_dns = "CLOUD_DNS"
  }
  depends_on = [google_compute_network.vpc]
}
resource "google_container_node_pool" "gke_1_nodes" {
  name       = "gke-1-node-pool"
  location   = var.zone_1
  cluster    = google_container_cluster.gke_1.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"


    service_account = data.google_compute_default_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Cluster 2
resource "google_container_cluster" "gke_2" {
  name                     = "gke-2"
  location                 = var.zone_2
  network                  = google_compute_network.vpc.id
  subnetwork               = google_compute_subnetwork.subnet_2.name
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  workload_identity_config {
    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"
  }
  fleet {
    project = var.project_id
  }
  dns_config {
    cluster_dns = "CLOUD_DNS"
  }
  depends_on = [google_compute_network.vpc]
}
resource "google_container_node_pool" "gke_2_nodes" {
  name       = "gke-2-node-pool"
  location   = var.zone_2
  cluster    = google_container_cluster.gke_2.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"


    service_account = data.google_compute_default_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
# GKE Hub Feature: Enable multicluster service discovery.
resource "google_gke_hub_feature" "multiclusterservice" {
  name     = "multiclusterservicediscovery"
  location = "global"
  project  = var.project_id
  depends_on = [
    google_container_cluster.gke_1,
    google_container_cluster.gke_2
  ]
}

# Artifact registry
resource "google_artifact_registry_repository" "my-repo" {
  location      = "us"
  repository_id = "my-repo"
  description   = "Docker repository"
  format        = "DOCKER"
}
