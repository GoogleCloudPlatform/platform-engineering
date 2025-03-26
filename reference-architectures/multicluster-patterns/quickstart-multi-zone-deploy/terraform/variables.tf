
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

variable "vpc_config" {
  description = "Configuration for the VPC network."
  type = object({
    network_name = string
    routing_mode = string
    subnets = list(object({
      subnet_name           = string
      subnet_ip             = string
      subnet_region         = string
      subnet_private_access = bool
    }))
    secondary_ranges = map(object({
      pod_range_name        = string
      pod_ip_cidr_range     = string
      service_range_name    = string
      service_ip_cidr_range = string
    }))
  })
}
variable "region" {
  description = "The region for Artifact Registry and Cloud Deploy."
  type        = string
}

variable "clusters" {
  description = "A map of cluster names and their corresponding zones."
  type = map(object({
    name                   = string
    zone                   = string
    is_config              = bool
    node_pool_machine_type = optional(string, "c2-standard-4")
    node_pool_disk_size_gb = optional(number, 30)
    labels                 = optional(map(string), {})
  }))
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
}
