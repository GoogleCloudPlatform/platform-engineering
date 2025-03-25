# terraform.tfvars

#project_id     = "your-gcp-project-id"
#project_id       = "pe-multi-cluster-zonal23"
vpc              = "default"
region           = "us-central1"
zone_1           = "us-central1-a"
zone_2           = "us-central1-b"
cluster_1_name   = "primary-cluster"
cluster_2_name   = "secondary-cluster"
namespace        = "store"
app_service_name = "store"
gatewayclass     = "gke-l7-global-external-managed-mc"
hostnames        = ["store.example.com"]
