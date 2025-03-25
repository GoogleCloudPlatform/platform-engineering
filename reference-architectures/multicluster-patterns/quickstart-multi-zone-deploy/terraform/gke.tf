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

output "cluster_ids" {
  value = { for k, v in module.gke : k => v.cluster_id }
}
