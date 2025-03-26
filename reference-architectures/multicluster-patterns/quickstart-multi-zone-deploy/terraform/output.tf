output "delivery_pipeline_name" {
  value = google_clouddeploy_delivery_pipeline.multi-cluster-pipeline.name
  }

output "cluster_ids" {
  value = { for k, v in module.gke : k => v.cluster_id }
}
