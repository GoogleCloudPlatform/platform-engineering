/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# variables.tf

variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "vpc" {
  description = "Project VPC"
  type        = string
}
variable "region" {
  description = "The region for Artifact Registry and Cloud Deploy."
  type        = string
}

variable "zone_1" {
  description = "The zone for the primary GKE cluster."
  type        = string
}

variable "zone_2" {
  description = "The zone for the secondary GKE cluster."
  type        = string
}

variable "cluster_1_name" {
  description = "The name of the primary GKE cluster."
  type        = string
  default     = "primary-cluster"
}

variable "cluster_2_name" {
  description = "The name of the secondary GKE cluster."
  type        = string
  default     = "secondary-cluster"
}
variable "namespace" {
  description = "Service namespace"
  type        = string
}
variable "app_service_name" {
  description = "The Service and Service Export name"
  type = string
}
variable "gatewayclass" {
  description = <<-EOT
    The type of multi-cluster Gateway to create. Choose from:
    - gke-l7-global-external-managed-mc: for global external multi-cluster Gateways
    - gke-l7-regional-external-managed-mc: for regional external multi-cluster Gateways
    - gke-l7-rilb-mc for regional internal multi-cluster Gateways
    - gke-l7-gxlb-mc for global external Classic multi-cluster Gateways
  EOT
  type        = string
}
variable "hostnames" {
  description = "HTTP Route hostnames"
  type = list(string)
}