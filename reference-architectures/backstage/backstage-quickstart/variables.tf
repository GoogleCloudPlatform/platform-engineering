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
  default     = "qs"
  description = "Name of the environment"
  type        = string
}

variable "iapSupportEmail" {
  description = "The email address for the IAP support contact"
  type        = string
  default     = ""
}

variable "iapUserDomain" {
  description = "The base domain name for the GCP org users accessing Backstage through IAP"
  type        = string
  default     = ""
}

variable "project_id_suffix" {
  description = "suffix to add to resources"
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

variable "region" {
  description = "Region for resources to be created"
  type        = string
  default     = "us-central1"
}

variable "backstageTechDocsBucket" {
  description = "The name for GCS bucket used with techdocs"
  type        = string
  default     = "backstage-qs-techdocs"
}

variable "backstageTechDocsBucketLocation" {
  description = "The GCS location for the bucket used with techdocs"
  type        = string
  default     = "US"
}

variable "backstageHostingProjectVpcName" {
  description = "Backstage Hosting VPC Name"
  type        = string
  default     = "backstage-qs"
}

variable "hostingSubnetName" {
  description = "Backstage Hosting Subnet Name"
  type        = string
  default     = "backstage-qs"
}

variable "hostingNodeCidr" {
  description = "Backstage Hosting Node CIDR"
  type        = string
  default     = "192.168.1.0/24"
}

variable "pscConsumerSubnetName" {
  description = "PSC Consumer Subnet Name"
  type        = string
  default     = "backstage-psc-consumer"
}

variable "pscConsumerCidr" {
  description = "PSC Consumer CIDR"
  type        = string
  default     = "192.168.2.0/24"
}

variable "cloudSqlPscConsumerIpName" {
  description = "CloudSQL PSC Consumer IP Name"
  type        = string
  default     = "backstage-qs-db-psc"
}

variable "cloudSqlPscConsumerIp" {
  description = "CloudSQL PSC Consumer IP"
  type        = string
  default     = "192.168.2.10"
}

variable "cloudsqlPscConsumerServicePolicyName" {
  description = "CloudSQL PSC Consumer Service Policy Name"
  type        = string
  default     = "cloudsql-psc"
}

variable "cloudsqlPscConsumerServicePolicyDescription" {
  description = "CloudSQL PSC Consumer Service Policy Description"
  type        = string
  default     = "cloudsql-psc-policy"
}

variable "cloudSqlPscZoneName" {
  description = "CloudSQL PSC Zone Name"
  type        = string
  default     = "cloudsql-psc"
}

variable "cloudSqlPscZoneDnsName" {
  description = "CloudSQL PSC Zone DNS Name"
  type        = string
  default     = "sql.goog."
}

variable "cloudSqlPscZoneDnsSuffix" {
  description = "CloudSQL PSC Zone DNS Suffix"
  type        = string
  default     = ".sql.goog."
}

variable "cloudSqlPscZoneDescription" {
  description = "CloudSQL PSC Zone Description"
  type        = string
  default     = "CloudSQL PSC Zone"
}

variable "privateCloudSqlIpName" {
  description = "Connection for private CloudSql"
  type        = string
  default     = "backstage-qs"

}

variable "backstageQsEndpointAddressName" {
  description = "Backstage QS Endpoint Address Name"
  type        = string
  default     = "backstage-qs-endpoint"
}

variable "cloudRouterName" {
  description = "name of cloud router"
  type        = string
  default     = "backstage-qs"
}

variable "natRouterName" {
  description = "name of nat router"
  type        = string
  default     = "backstage-qs"
}

variable "backstageHostingRepo" {
  description = "Name for backstage container repo"
  type        = string
  default     = "backstage-qs"
}

variable "backstageRepoDescription" {
  description = "Description for repo"
  type        = string
  default     = "Backstage Quick Start"
}

variable "cloudSqlInstanceName" {
  description = "Name for backstage DB instance"
  type        = string
  default     = "backstage-qs"
}

variable "hostingClusterName" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "backstage-qs"
}

variable "hostingSaId" {
  description = "The name of the backstage node SA"
  type        = string
  default     = "backstage-qs-hosting"
}


variable "hostingSaDisplayName" {
  description = "The display name for the backstage node SA"
  type        = string
  default     = "Backstage Hosting Node"
}

variable "workloadSaId" {
  description = "The name of the backstage workload SA"
  type        = string
  default     = "backstage-qs-workload"
}

variable "workloadSaDisplayName" {
  description = "The display name for the backstage workload SA"
  type        = string
  default     = "Backstage Workload"
}

variable "dbPasswordSecretName" {
  description = "The name of the DB PW secret"
  type        = string
  default     = "backstage-qs-postgres-pw"
}

variable "dbIpSecretName" {
  description = "The name of the DB IP secret"
  type        = string
  default     = "backstage-qs-postgres-ip"
}

variable "dbIamUserSecretName" {
  description = "The name of the IAM Username secret"
  type        = string
  default     = "backstage-qs-postgres-iam-user"
}

variable "dbInstanceSecretName" {
  description = "The name of the DB instance name secret"
  type        = string
  default     = "backstage-qs-postgres-instance-name"
}

variable "backstageIapApplicationTitle" {
  description = "The title of the IAP protected Backstage application"
  type        = string
  default     = "IAP Protected Backstage on GCP"
}

variable "backstageIapDisplayName" {
  description = "The display name of the IAP protected Backstage application"
  type        = string
  default     = "Backstage on GCP"
}