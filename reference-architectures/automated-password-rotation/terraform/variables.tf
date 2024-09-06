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

variable "db_user" {
  type        = string
  default     = "user1"
  description = "db user in cloudsql"
}

variable "db_name" {
  type        = string
  default     = "test"
  description = "db name in cloudsql"
}

variable "project_id" {
  type        = string
  description = "gcp project"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "location"
}

variable "instance_name" {
  type        = string
  default     = "cloudsql-for-pg"
  description = "Instance name in cloudsql"
}

variable "services" {
  type        = list(string)
  description = "Service to enable in the GCP project"
  default     = ["eventarc.googleapis.com", "run.googleapis.com", "servicenetworking.googleapis.com", "compute.googleapis.com", "vpcaccess.googleapis.com", "secretmanager.googleapis.com", "cloudfunctions.googleapis.com", "pubsub.googleapis.com", "iam.googleapis.com", "artifactregistry.googleapis.com", "cloudscheduler.googleapis.com", "sqladmin.googleapis.com", "cloudbuild.googleapis.com"]
}

variable "ce_sa_roles" {
  type        = list(string)
  description = "Roles to be granted to default compute engine CE for CloudBuild to be able to deploy Cloud Function"
  default     = ["roles/logging.logWriter", "roles/storage.objectViewer", "roles/artifactregistry.writer"]
}

variable "connector_machine_type" {
  type        = string
  default     = "e2-micro"
  description = "Imachine trype for serverless VPC conenctor"
}

variable "connector_cidr" {
  type        = string
  default     = "10.8.0.0/28"
  description = "CIDR range for Serverless VPC connector"
}

variable "vpc_network" {
  type        = string
  default     = "default"
  description = "VPC network for Serverless VPC conenctor"
}

variable "connector_name" {
  type        = string
  default     = "connector-for-cloudsql"
  description = "Name of the Serverless VPC connector"
}

variable "database_version" {
  type        = string
  default     = "POSTGRES_14"
  description = "CloudSql DB version"
}

variable "db_instance_tier" {
  type        = string
  default     = "db-f1-micro"
  description = "db instance tier"
}

variable "scheduler_sa" {
  type        = string
  default     = "pswd-rotation-scheduler-sa"
  description = "Service account for the cloud scheduler"
}

variable "function_sa" {
  type        = string
  default     = "pswd-rotation-function-sa"
  description = "Service account for the cloud function"
}

variable "scheduler_name" {
  type        = string
  default     = "password-rotator-job"
  description = "Name of the cloud scheduler"
}

