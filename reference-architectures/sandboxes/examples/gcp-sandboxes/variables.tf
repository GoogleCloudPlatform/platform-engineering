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
  description = "The billing account that will be attached to the system project. This billing account can be different from the billing acount used for the sandboxes, but is not shown in this example."
  type        = string
}

variable "sandboxes_folder" {
  description = "Name of the folder that the system project and sandboxes will be created in."
  type        = string
  default     = "us-central1"
}

variable "sandboxes_folder" {
  description = "The folder the system project will be created in, needs to be in the format of folders/<folder_id>. This folder id can be different from the folder used for the sandboxes, but is not demonstrated in this example."
  type        = string
}

variable "system_project_id" {
  description = "Project ID for the system project."
  type        = string
}
