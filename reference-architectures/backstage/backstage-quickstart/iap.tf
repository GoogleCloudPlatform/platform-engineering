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

data "google_project" "backstageProject" {
  project_id = var.environment_project_id
}

resource "google_iap_web_iam_member" "backstageIapPolicy" {
  project = var.environment_project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "domain:${var.iap_user_domain}"
}

resource "google_iap_client" "backstageIapClient" {
  display_name = var.backstage_iap_display_name
  brand        = "projects/${data.google_project.backstageProject.number}/brand/${data.google_project.backstageProject.number}"
}

resource "local_file" "route_https_yaml" {
  content = templatefile(
    "${path.module}/manifests/templates/http-route-service.tftpl.yaml",
    {
      gateway_name    = local.gateway_name
      hostname        = local.backstageExternalUrl
      http_route_name = "backstage-https"
      namespace       = "backstage"
      service_name    = "backstage"
      service_port    = 80
    }
  )
  filename = "./manifests/k8s/http-route-service.yaml"
}

###############################################################################
# IAP Policy
###############################################################################

resource "local_file" "iap_secret_yaml" {
  content = templatefile(
    "${path.module}/manifests/templates/oauth-secret.tftpl.yaml",
    {
      name      = "backstage-oauth"
      namespace = "backstage"
      secret    = base64encode(google_iap_client.backstageIapClient.secret)
    }
  )
  filename = "./manifests/k8s/oauth-secret.yaml"
}

resource "local_file" "policy_iap_backstage_yaml" {
  content = templatefile(
    "${path.module}/manifests/templates/gcp-backend-policy-iap-service.tftpl.yaml",
    {
      oauth_client_id          = google_iap_client.backstageIapClient.client_id
      oauth_client_secret_name = "backstage-oauth"
      policy_name              = "backstage"
      service_name             = "backstage"
      namespace                = "backstage"
    }
  )
  filename = "./manifests/k8s/gcp-backend-policy-iap-service.yaml"
}
