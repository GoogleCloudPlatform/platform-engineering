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

variable "billing_account" {
  description = "Billing account for the sandboxes"
  type        = string
}

variable "firestore_location" {
  description = "Location to be used for the Cloud Firestore database. If not specified the default value is var.region"
  type        = string
  default     = ""
}

variable "gcs_location" {
  description = "Location that the GCS buckets for Terraform templates and state. If not specified the default value is var.region"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region the sandboxes system project will be created in."
  type        = string
}

variable "sandboxes_folder" {
  description = "Name of the folder that the system project and sandboxes will be created in."
  type        = string
}

variable "system_project_id" {
  description = "Project ID of the system project for the sandboxes."
  type        = string

  validation = {
    condition     = length(var.system_project_id) >= 4 && length(var.system_project_id) <= 30
    error_message = "The system_project_name must be between 4 and 30 characters"
  }
}
