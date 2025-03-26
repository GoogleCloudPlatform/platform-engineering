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

 # Service APIs
 locals {
  required_apis = [
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "clouddeploy.googleapis.com",
    "cloudbuild.googleapis.com",
    "gkehub.googleapis.com",
    "trafficdirector.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "multiclusteringress.googleapis.com",
  ]
}

resource "google_project_service" "required_apis" {
  for_each = toset(local.required_apis)
  project  = var.project_id
  service  = each.value

  disable_on_destroy = false
}

# Setup VPC
module "vpc" {
  depends_on = [ google_project_service.required_apis ]
  source       = "terraform-google-modules/network/google"
  project_id   = var.project_id
  network_name = var.vpc_config.network_name
  routing_mode = var.vpc_config.routing_mode

  subnets = [
    for subnet in var.vpc_config.subnets : {
      subnet_name            = subnet.subnet_name
      subnet_ip              = subnet.subnet_ip
      subnet_region          = subnet.subnet_region
      subnet_private_access  = subnet.subnet_private_access
      subnet_region          = var.region 
    }
  ]

  secondary_ranges = {
    for subnet_name, ranges in var.vpc_config.secondary_ranges :
    subnet_name => [
      {
        range_name     = ranges.pod_range_name
        ip_cidr_range = ranges.pod_ip_cidr_range
      },
      {
        range_name     = ranges.service_range_name
        ip_cidr_range = ranges.service_ip_cidr_range
      }
    ]
  }
}

# Setup Artifact registry
 resource "google_artifact_registry_repository" "docker_repositories" {
  depends_on = [ google_project_service.required_apis ]
  project       = var.project_id
  location      = var.region
  repository_id = "main"
  labels        = var.labels
  description   = "my docker repository"
  format        = "DOCKER"
}

# GKE Clusters
resource "null_resource" "clusters" {
  for_each = var.clusters

  provisioner "local-exec" {
    command = "echo Creating cluster ${each.value.name} in zone ${each.value.zone}"
  }
}
module "gke" {
  depends_on = [module.vpc, null_resource.clusters, google_project_service.required_apis]
  for_each   = var.clusters
  source     = "terraform-google-modules/kubernetes-engine/google"

  project_id                 = var.project_id
  name                       = each.value.name
  regional                   = false
  zones                      = [each.value.zone]
  network                    = module.vpc.network_name
  subnetwork                 = module.vpc.subnets_names[0]
  ip_range_pods              = var.vpc_config.secondary_ranges[module.vpc.subnets_names[0]].pod_range_name
  ip_range_services          = var.vpc_config.secondary_ranges[module.vpc.subnets_names[0]].service_range_name
  http_load_balancing        = true
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  deletion_protection        = false
  enable_cost_allocation     = true
  fleet_project              = var.project_id
  gateway_api_channel        = "CHANNEL_STANDARD"

  node_pools = [
    {
      name            = "node-pool-1"
      machine_type    = each.value.node_pool_machine_type
      node_locations  = "${each.value.zone}"
      min_count       = 1
      max_count       = 2
      local_ssd_count = 0

      spot            = false
      disk_size_gb    = each.value.node_pool_disk_size_gb
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      enable_gcfs     = false
      enable_gvnic    = false
      logging_variant = "DEFAULT"
      auto_repair     = true
      auto_upgrade    = true
      preemptible     = false
    },
  ]

  node_pools_labels = {
    all = var.labels
  }
}

# GKE Hub Feature: Enable multicluster service discovery.
resource "google_gke_hub_feature" "multiclusterservice" {
  name       = "multiclusterservicediscovery"
  location   = "global"
  project    = var.project_id
  depends_on = [module.vpc]
}

# GKE Hub Feature: Enable multicluster gateway (ingress).
resource "google_gke_hub_feature" "multiclustergateway" {
  name     = "multiclusteringress"
  location = "global"
  project  = var.project_id
  spec {
    multiclusteringress {
      config_membership = "projects/${var.project_id}/locations/${var.region}/memberships/${var.clusters["config-cluster"].name}"
    }
  }
  depends_on = [
    module.gke,
    google_gke_hub_feature.multiclusterservice,
  ]
}

# Cloud Deploy Delivery Pipeline: Define the delivery pipeline.
resource "google_clouddeploy_delivery_pipeline" "multi-cluster-pipeline" {
  depends_on = [ module.gke ]
  location    = var.region
  name        = "multi-target-pipeline"
  description = "Delivery pipeline"
  project     = var.project_id
  serial_pipeline {
    stages {
      profiles  = ["config-cluster"]
      target_id = google_clouddeploy_target.targets["config-cluster"].target_id
    }
    stages {
      profiles  = ["worker-cluster"]
      target_id = google_clouddeploy_target.targets["cluster-1"].target_id
    }
    stages {
      profiles = ["worker-cluster"]
      target_id = google_clouddeploy_target.targets["cluster-2"].target_id
    }
  }

  labels = var.labels
}

# Cloud Deploy Targets
resource "google_clouddeploy_target" "targets" {
  depends_on = [module.gke]
  for_each   = var.clusters
  location   = var.region
  name       = "${each.value.name}-target"
  project    = var.project_id
  labels     = merge(var.labels, each.value.labels)

  gke {
    cluster = module.gke[each.key].cluster_id
  }
}

