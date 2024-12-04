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


resource "google_compute_network" "backstageHostingVpc" {
  project                 = var.environment_project_id
  name                    = var.backstageHostingProjectVpcName
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "backstageHostingNodeSubnet" {
  project       = var.environment_project_id
  region        = var.region
  network       = google_compute_network.backstageHostingVpc.self_link
  name          = var.hostingSubnetName
  ip_cidr_range = var.hostingNodeCidr
}

resource "google_compute_subnetwork" "pscConsumerSubnet" {
  project       = var.environment_project_id
  region        = var.region
  network       = google_compute_network.backstageHostingVpc.self_link
  name          = var.pscConsumerSubnetName
  ip_cidr_range = var.pscConsumerCidr
}

resource "google_compute_address" "cloudSqlPscConsumerIp" {
  name         = var.cloudSqlPscConsumerIpName
  project      = var.environment_project_id
  subnetwork   = google_compute_subnetwork.pscConsumerSubnet.id
  address_type = "INTERNAL"
  address      = var.cloudSqlPscConsumerIp
  region       = var.region
}

resource "google_compute_router" "cloudRouter" {
  project = var.environment_project_id
  name    = var.cloudRouterName
  region  = google_compute_subnetwork.backstageHostingNodeSubnet.region
  network = google_compute_network.backstageHostingVpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  project                            = var.environment_project_id
  name                               = var.natRouterName
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
  name        = var.cloudSqlPscZoneName
  dns_name    = var.cloudSqlPscZoneDnsName
  description = var.cloudSqlPscZoneDescription

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

  rrdatas = [var.cloudSqlPscConsumerIp]
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

resource "google_compute_global_address" "backstageQsEndpointAddress" {
  name    = var.backstageQsEndpointAddressName
  project = var.environment_project_id
}