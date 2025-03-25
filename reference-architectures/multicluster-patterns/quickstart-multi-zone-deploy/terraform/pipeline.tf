
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

output "delivery_pipeline_name" {
  value = google_clouddeploy_delivery_pipeline.multi-cluster-pipeline.name
  }