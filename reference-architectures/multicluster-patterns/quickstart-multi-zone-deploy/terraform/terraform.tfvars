# terraform.tfvars

region = "us-central1"

# VPC Config
vpc_config = {
    network_name   = "vpc-default"
    routing_mode   = "GLOBAL"
    subnets        = [
      {
        subnet_name            = "public-subnet"
        subnet_ip              = "10.0.2.0/24"
        subnet_region          = "us-central1"
        subnet_private_access  = false
      }
    ]
    secondary_ranges = {
      public-subnet = {
        pod_range_name       = "ip-range-pods"
        pod_ip_cidr_range    = "10.90.0.0/16"
        service_range_name   = "ip-range-services"
        service_ip_cidr_range = "10.95.0.0/16"
      }
    }
  }
# Zonal cluster in us-central
clusters = {
  config-cluster = {
    name      = "config-cluster",
    zone      = "us-central1-a",
    is_config = true
  }
  cluster-1 = {
    name      = "cluster-1",
    zone      = "us-central1-b"
    is_config = false
  }
  cluster-2 = {
    name      = "cluster-2",
    zone      = "us-central1-c"
    is_config = false
  }
}
# Resource labels
labels = {
  environment         = "demo"
  data-classification = "na"
  cost-center         = "dev-ops"
  team                = "platform-team"
  component           = "base-setup"
  application         = "multicluster-demo"
  compliance          = "na"
}
