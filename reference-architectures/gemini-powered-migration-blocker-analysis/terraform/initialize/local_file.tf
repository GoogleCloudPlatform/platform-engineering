
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

locals {
  base_directory   = "${path.module}/../"
  backend_template = "${path.module}/templates/terraform/backend.tf.tftpl"

  core_backend_directories = toset([for _, version_file in local.core_versions_files : trimprefix(trimsuffix(version_file, "/versions.tf"), "../")])
  core_versions_files      = flatten([for _, file in flatten(fileset(local.base_directory, "**/versions.tf")) : file])

  shared_config_folder = "${path.module}/../_shared_config"
}

resource "local_file" "core_backend_tf" {
  for_each = local.core_backend_directories
  content = templatefile(
    local.backend_template,
    {
      bucket = local.terraform_bucket_name,
      prefix = "terraform/${each.key}",
    }
  )
  file_permission = "0644"
  filename        = "${local.base_directory}/${each.key}/backend.tf"
}

resource "local_file" "shared_config_initialize_auto_tfvars" {
  content = provider::terraform::encode_tfvars(
    {
      default_project_id = var.default_project_id
    }
  )
  file_permission = "0644"
  filename        = "${local.shared_config_folder}/initialize.auto.tfvars"
}

resource "local_file" "shared_config_platform_auto_tfvars" {
  content = provider::terraform::encode_tfvars(
    {
      platform_name        = var.platform_name
      resource_name_prefix = var.resource_name_prefix
    }
  )
  file_permission = "0644"
  filename        = "${local.shared_config_folder}/platform.auto.tfvars"
}

resource "local_file" "shared_config_terraform_auto_tfvars" {
  content = provider::terraform::encode_tfvars(
    {
      terraform_backend_bucket_location = var.terraform_backend_bucket_location
      terraform_project_id              = var.terraform_project_id
    }
  )
  file_permission = "0644"
  filename        = "${local.shared_config_folder}/terraform.auto.tfvars"
}
