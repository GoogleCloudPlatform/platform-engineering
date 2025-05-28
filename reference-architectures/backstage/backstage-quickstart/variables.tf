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
  default     = "qs"
}

variable "iap_support_email" {
  description = "The email address for the IAP support contact"
  type        = string
}

variable "iap_user_domain" {
  description = "The base domain name for the GCP org users accessing Backstage through IAP"
  type        = string
}

variable "environment_project_id" {
  description = "The GCP project where the resources will be created"
  type        = string

  validation {
    condition     = var.environment_project_id != "YOUR_PROJECT_ID"
    error_message = "'environment_project_id' was not set, please set the value in the backstage-qs.auto.tfvars file"
  }
}

variable "backstage_hosting_project_services" {
  description = "Service APIs to enable"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com",
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
    "iap.googleapis.com"
  ]
}

variable "region" {
  description = "Region for resources to be created"
  type        = string
  default     = "us-central1"
}

variable "backstage_tech_docs_bucket" {
  description = "The name for GCS bucket used with techdocs"
  type        = string
  default     = "backstage-qs-techdocs"
}

variable "backstage_tech_docs_bucket_location" {
  description = "The GCS location for the bucket used with techdocs"
  type        = string
  default     = "US"
}

variable "backstage_hosting_project_vpc_name" {
  description = "Backstage Hosting VPC Name"
  type        = string
  default     = "backstage-qs"
}

variable "hosting_subnet_name" {
  description = "Backstage Hosting Subnet Name"
  type        = string
  default     = "backstage-qs"
}

variable "hosting_node_cidr" {
  description = "Backstage Hosting Node CIDR"
  type        = string
  default     = "192.168.1.0/24"
}

variable "psc_consumer_subnet_name" {
  description = "PSC Consumer Subnet Name"
  type        = string
  default     = "backstage-psc-consumer"
}

variable "psc_consumer_cidr" {
  description = "PSC Consumer CIDR"
  type        = string
  default     = "192.168.2.0/24"
}

variable "cloudsql_psc_consumer_ip_name" {
  description = "CloudSQL PSC Consumer IP Name"
  type        = string
  default     = "backstage-qs-db-psc"
}

variable "cloudsql_psc_consumer_ip" {
  description = "CloudSQL PSC Consumer IP"
  type        = string
  default     = "192.168.2.10"
}

variable "cloudsql_psc_consumer_service_policy_name" {
  description = "CloudSQL PSC Consumer Service Policy Name"
  type        = string
  default     = "cloudsql-psc"
}

variable "cloudsql_psc_consumer_service_policy_description" {
  description = "CloudSQL PSC Consumer Service Policy Description"
  type        = string
  default     = "cloudsql-psc-policy"
}

variable "cloudsql_psc_zone_name" {
  description = "CloudSQL PSC Zone Name"
  type        = string
  default     = "cloudsql-psc"
}

variable "cloudsql_psc_zone_dns_name" {
  description = "CloudSQL PSC Zone DNS Name"
  type        = string
  default     = "sql.goog."
}

variable "cloudsql_psc_zone_dns_suffix" {
  description = "CloudSQL PSC Zone DNS Suffix"
  type        = string
  default     = ".sql.goog."
}

variable "cloudsql_psc_zone_description" {
  description = "CloudSQL PSC Zone Description"
  type        = string
  default     = "CloudSQL PSC Zone"
}

variable "private_cloudsql_ip_name" {
  description = "Connection for private CloudSql"
  type        = string
  default     = "backstage-qs"

}

variable "backstageqs_endpoint_address_name" {
  description = "Backstage QS Endpoint Address Name"
  type        = string
  default     = "backstage-qs-endpoint"
}

variable "cloud_router_name" {
  description = "name of cloud router"
  type        = string
  default     = "backstage-qs"
}

variable "nat_router_name" {
  description = "name of nat router"
  type        = string
  default     = "backstage-qs"
}

variable "backstage_hosting_repo_name" {
  description = "Name for backstage container repo"
  type        = string
  default     = "backstage-qs"
}

variable "backstage_hosting_repo_description" {
  description = "Description for repo"
  type        = string
  default     = "Backstage Quick Start"
}

variable "cloudsql_instance_name" {
  description = "Name for backstage DB instance"
  type        = string
  default     = "backstage-qs"
}

variable "hosting_cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "backstage-qs"
}

variable "hosting_sa_id" {
  description = "The name of the backstage node SA"
  type        = string
  default     = "backstage-qs-hosting"
}


variable "hosting_sa_display_name" {
  description = "The display name for the backstage node SA"
  type        = string
  default     = "Backstage Hosting Node"
}

variable "workload_sa_id" {
  description = "The name of the backstage workload SA"
  type        = string
  default     = "backstage-qs-workload"
}

variable "workload_sa_display_name" {
  description = "The display name for the backstage workload SA"
  type        = string
  default     = "Backstage Workload"
}

variable "db_password_secret_name" {
  description = "The name of the DB PW secret"
  type        = string
  default     = "backstage-qs-postgres-pw"
}

variable "db_ip_secret_name" {
  description = "The name of the DB IP secret"
  type        = string
  default     = "backstage-qs-postgres-ip"
}

variable "db_iam_user_secret_name" {
  description = "The name of the IAM Username secret"
  type        = string
  default     = "backstage-qs-postgres-iam-user"
}

variable "db_instance_secret_name" {
  description = "The name of the DB instance name secret"
  type        = string
  default     = "backstage-qs-postgres-instance-name"
}

variable "backstage_iap_application_title" {
  description = "The title of the IAP protected Backstage application"
  type        = string
  default     = "IAP Protected Backstage on GCP"
}

variable "backstage_iap_display_name" {
  description = "The display name of the IAP protected Backstage application"
  type        = string
  default     = "Backstage on GCP"
}
