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

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  provider_meta "google" {
    module_name = "cloud-solutions/platform-engineering-backstage-quickstart-deploy-v1"
  }

}

locals {
  backend_file             = "../backend.tf"
  project_id_prefix        = "${var.project.name}-${var.environment_name}"
  project_id_suffix_length = 29 - length(local.project_id_prefix)
  tfvars_file              = "../backstage-qs.auto.tfvars"
  tfvars_contents          = <<-EOT
    environment_name        = "${var.environment_name}"
    iap_user_domain         = "${var.iap_user_domain}"
    environment_project_id  = "${google_project.environment.project_id}"
    project_id_suffix       = "${random_string.project_id_suffix.result}"
    iap_support_email       = "${var.iap_support_email}"
  EOT
}

resource "local_file" "backstage_qs_auto_tfvars" {
  filename = local.tfvars_file
  content  = local.tfvars_contents
}

resource "random_string" "project_id_suffix" {
  length  = local.project_id_suffix_length
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "google_project" "environment" {
  billing_account = var.project.billing_account_id
  folder_id       = var.project.folder_id == "" ? null : var.project.folder_id
  name            = local.project_id_prefix
  org_id          = var.project.org_id == "" ? null : var.project.org_id
  project_id      = "${local.project_id_prefix}-${random_string.project_id_suffix.result}"
  deletion_policy = "DELETE"
}

resource "google_project_service" "backstageHostingProjectServices" {
  for_each                   = toset(var.backstage_hosting_project_services)
  project                    = google_project.environment.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

resource "google_storage_bucket" "backstage-qs" {
  force_destroy               = false
  location                    = var.state_storage_bucket_location
  name                        = "${google_project.environment.project_id}-backstage-qs"
  project                     = google_project.environment.project_id
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}


resource "null_resource" "write_storage_bucket" {
  triggers = {
    backend_file = local.backend_file
    md5          = google_storage_bucket.backstage-qs.name
  }

  provisioner "local-exec" {
    command     = <<EOT
echo "Writing 'bucket' changes to '${local.backend_file}'" && \
sed -i 's/^\([[:blank:]]*bucket[[:blank:]]*=\).*$/\1 ${jsonencode(google_storage_bucket.backstage-qs.name)}/' ${local.backend_file} && \
sed -i 's/^\([[:blank:]]*bucket[[:blank:]]*=\).*$/\1 ${jsonencode(google_storage_bucket.backstage-qs.name)}/' backend.tf.bucket && \
mv backend.tf backend.tf.local && \
cp backend.tf.bucket backend.tf
    EOT
    interpreter = ["bash", "-c"]
    working_dir = path.module
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<EOT
echo "Reverting 'bucket' changes in '${self.triggers.backend_file}'" && \
sed -i 's/^\([[:blank:]]*bucket[[:blank:]]*=\).*$/\1 "YOUR_STATE_BUCKET"/' ${self.triggers.backend_file} && \
sed -i 's/^\([[:blank:]]*bucket[[:blank:]]*=\).*$/\1 ""/' backend.tf.bucket
    EOT
    interpreter = ["bash", "-c"]
    working_dir = path.module
  }
}
