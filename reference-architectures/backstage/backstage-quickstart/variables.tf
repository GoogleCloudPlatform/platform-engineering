# Copyright 2025 Google LLC
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

variable "iap_user_domain" {
  description = "The base domain name for the GCP org users accessing Backstage through IAP"
  type        = string
}

variable "iap_client_id" {
  description = "The id of the IAP client"
  type        = string
}

variable "iap_client_secret" {
  description = "OAuth secret for the IAP client"
  type        = string
  sensitive   = true
}

variable "environment_project_id" {
  description = "The GCP project where the resources will be created"
  type        = string

  validation {
    condition     = var.environment_project_id != "YOUR_PROJECT_ID"
    error_message = "'environment_project_id' was not set, please set the value in the backstage-qs.auto.tfvars file"
  }
}
