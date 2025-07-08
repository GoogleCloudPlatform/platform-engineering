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

locals {
  gateway_name                = "external-https"
}

resource "google_compute_network" "backstageHostingVpc" {
  project                 = var.environment_project_id
  name                    = var.backstage_hosting_project_vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "backstageHostingNodeSubnet" {
  project       = var.environment_project_id
  region        = var.region
  network       = google_compute_network.backstageHostingVpc.self_link
  name          = var.hosting_subnet_name
  ip_cidr_range = var.hosting_node_cidr
}

resource "google_compute_subnetwork" "pscConsumerSubnet" {
  project       = var.environment_project_id
  region        = var.region
  network       = google_compute_network.backstageHostingVpc.self_link
  name          = var.psc_consumer_subnet_name
  ip_cidr_range = var.psc_consumer_cidr
}

resource "google_compute_address" "cloudSqlPscConsumerIp" {
  name         = var.cloudsql_psc_consumer_ip_name
  project      = var.environment_project_id
  subnetwork   = google_compute_subnetwork.pscConsumerSubnet.id
  address_type = "INTERNAL"
  address      = var.cloudsql_psc_consumer_ip
  region       = var.region
}

resource "google_compute_router" "cloudRouter" {
  project = var.environment_project_id
  name    = var.cloud_router_name
  region  = google_compute_subnetwork.backstageHostingNodeSubnet.region
  network = google_compute_network.backstageHostingVpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  project                            = var.environment_project_id
  name                               = var.nat_router_name
  router                             = google_compute_router.cloudRouter.name
  region                             = google_compute_router.cloudRouter.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_dns_managed_zone" "cloudSqlPscZone" {
  project     = var.environment_project_id
  name        = var.cloudsql_psc_zone_name
  dns_name    = var.cloudsql_psc_zone_dns_name
  description = var.cloudsql_psc_zone_description

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.backstageHostingVpc.id
    }
  }
}

resource "google_dns_record_set" "cloudSqlPscRecord" {
  project      = var.environment_project_id
  name         = google_sql_database_instance.instance.dns_name
  managed_zone = google_dns_managed_zone.cloudSqlPscZone.name
  type         = "A"
  ttl          = 1

  rrdatas = [var.cloudsql_psc_consumer_ip]
}

resource "google_compute_forwarding_rule" "cloudSqlPscForwardingRule" {
  name                  = "psc-forwarding-rule-${google_sql_database_instance.instance.name}"
  project               = var.environment_project_id
  region                = var.region
  network               = google_compute_network.backstageHostingVpc.id
  ip_address            = google_compute_address.cloudSqlPscConsumerIp.id
  load_balancing_scheme = ""
  target                = google_sql_database_instance.instance.psc_service_attachment_link
}

# Firewall rule required to support IAM logins to Cloud SQL
# https://cloud.google.com/sql/docs/postgres/iam-logins
resource "google_compute_firewall" "cloud_sql_auth" {
  name = "cloudsql-auth"
  network = google_compute_network.backstageHostingVpc.id
  
  allow {
    protocol  = "tcp"
    ports     = ["443", "3307"]
  }
  direction = "EGRESS"
  destination_ranges = ["34.126.0.0/18"]
  target_service_accounts = [google_service_account.workloadSa.email]
}


resource "google_compute_global_address" "backstageQsEndpointAddress" {
  name    = var.backstageqs_endpoint_address_name
  project = var.environment_project_id
}

resource "local_file" "gateway_external_https_yaml" {
  depends_on = [
    google_compute_global_address.backstageQsEndpointAddress
  ]

  content = templatefile(
    "${path.module}/manifests/templates/gateway-external-https.tftpl.yaml",
    {
      address_name         = google_compute_global_address.backstageQsEndpointAddress.name
      gateway_name         = local.gateway_name
      namespace            = "backstage"
      ssl_certificate_name = google_compute_managed_ssl_certificate.backstageCert.name
    }
  )
  filename = "${path.module}/manifests/k8s/gateway-external-https.yaml"
}
