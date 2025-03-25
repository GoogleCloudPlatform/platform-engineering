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