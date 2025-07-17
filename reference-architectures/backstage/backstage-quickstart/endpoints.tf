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
  backstageExternalUrl = "${var.environment_name}.endpoints.${var.environment_project_id}.cloud.goog"
}

resource "google_endpoints_service" "backstageQsEndpoint" {
  openapi_config = templatefile(
    "${path.module}/manifests/templates/backstage-qs-endpoint-spec-tftpl.yaml",
    {
      endpoint   = local.backstageExternalUrl,
      ip_address = google_compute_global_address.backstageQsEndpointAddress.address
    }
  )
  project      = var.environment_project_id
  service_name = local.backstageExternalUrl
}

resource "google_compute_managed_ssl_certificate" "backstageCert" {
  name = "backstage-qs-cert"

  managed {
    domains = [local.backstageExternalUrl]
  }

  depends_on = [time_sleep.wait_for_apis]
}
