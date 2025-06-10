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

/*
 * The files in the sandbox module will get moved to the root of the bucket.
 * Prior to uploading to the bucket "TERRAFORM_GCS_BUCKET" needs to be updated
 * to point to the actual bucket, which is hosting the Terraform for the system
 * project.
 */

module "project" {
  source = "gcs::https://www.googleapis.com/storage/v1/TERRAFORM_GCS_BUCKET/fabric-modules/project"

  name            = var.project_id
  billing_account = var.billing_account
  parent          = var.parent_folder
}
