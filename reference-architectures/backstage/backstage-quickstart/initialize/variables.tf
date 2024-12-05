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

variable "environment_name" {
  description = "Name of the environment"
  type        = string
}

variable "iapSupportEmail" {
  description = "The email address for the IAP support contact"
  type        = string
}

variable "iapUserDomain" {
  description = "The base domain name for the GCP org users accessing Backstage through IAP"
  type        = string
}

variable "project" {
  default = {
    billing_account_id = ""
    folder_id          = ""
    name               = "backstage"
    org_id             = ""
  }

  type = object({
    billing_account_id = string
    folder_id          = string
    name               = string
    org_id             = string
  })

  validation {
    condition     = var.project.billing_account_id == "" || can(regex("^[[:xdigit:]]{6}-[[:xdigit:]]{6}-[[:xdigit:]]{6}$", var.project.billing_account_id))
    error_message = "Google Cloud billing account ID can only contain hexidecimal characters[0-9A-Fa-f] and must be in the format XXXXXX-XXXXXX-XXXXXX."
  }

  validation {
    condition     = var.project.folder_id == "" || can(regex("^[[:digit:]]+$", var.project.folder_id))
    error_message = "Google Cloud folder ID must be all digits[0-9]."
  }

  validation {
    condition     = var.project.name == "" || can(regex("^[-0-9A-Za-z' !]{3,30}$", var.project.name))
    error_message = "Google Cloud Project name must be 3 to 30 characters in length and can only contain letters[A-Za-z], numbers[0-0], single quotes['], hyphens[-], spaces[ ] or exclamation points[!]."
  }

  validation {
    condition     = var.project.org_id == "" || can(regex("^[[:digit:]]+$", var.project.org_id))
    error_message = "Google Cloud organization ID must be all digits[0-9]."
  }

  validation {
    condition     = !(var.project.billing_account_id == "")
    error_message = "A Google Cloud billing account ID is required."
  }

  validation {
    condition     = !(var.project.folder_id == "" && var.project.org_id == "")
    error_message = "Set 'project.folder_id' OR 'project.org_id'."
  }

  validation {
    condition     = !(var.project.folder_id != "" && var.project.org_id != "")
    error_message = "Set \"either\" 'project.folder_id' OR 'project.org_id', both cannot be provided."
  }
}

variable "state_storage_bucket_location" {
  default     = "us-central1"
  description = "Cloud Storage bucket location"
  type        = string
}

variable "backstageHostingProjectServices" {
  description = "Service APIs to enable"
  type        = list(string)
  default = ["artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "autoscaling.googleapis.com",
    "containerfilesystem.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "dns.googleapis.com",
  "iap.googleapis.com"]
}