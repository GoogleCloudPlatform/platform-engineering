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

#
# System Project
#

module "system_project" {
  source = "../../../fabric-modules/project"

  name            = var.system_project_id
  parent          = var.sandboxes_folder
  billing_account = var.billing_account

  services = [
    "cloudbilling.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "config.googleapis.com",
    "eventarc.googleapis.com",
    "firebase.googleapis.com",
    "firebaseextensions.googleapis.com",
    "firestore.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com"
  ]
}

#
# Sandbox Terraform and Infra Manager
#

module "terraform_bucket" {
  source = "../../../fabric-modules/gcs"

  project_id = module.system_project.id
  name       = "${module.system_project.name}_terraform"
  location   = "US"
  versioning = true
}

module "terraform_state_bucket" {
  source = "../../../fabric-modules/gcs"

  project_id = module.system_project.id
  name       = "${module.system_project.name}_terraform_state"
  location   = "US"
  versioning = true
}

resource "null_resource" "upload_tf" {
  provisioner "local-exec" {
    command = <<EOT
      find ${abspath("${path.module}/../../../catalog")} -type f -name '*.tf' -exec sed -i 's/TERRAFORM_GCS_BUCKET/${module.terraform_bucket.name}/g' {} +
      gcloud storage rsync ${abspath("${path.module}/../../../fabric-modules")} gs://${module.terraform_bucket.name}/fabric-modules/ --recursive --delete-unmatched-destination-objects
      gcloud storage rsync ${abspath("${path.module}/../../../catalog")} gs://${module.terraform_bucket.name}/catalog/ --recursive
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

module "sandbox_factory_sa" {
  source = "../../../fabric-modules/iam-service-account"

  project_id = module.system_project.id
  name       = "sandbox-factory-sa"

  iam_billing_roles = {
    "${var.billing_account}" = [
      "roles/billing.user"
    ]
  }

  iam_folder_roles = {
    "${var.sandboxes_folder}" = [
      "roles/resourcemanager.projectCreator",
      "roles/resourcemanager.projectDeleter"
    ]
  }

  iam_project_roles = {
    "${module.system_project.id}" = [
      "roles/cloudbuild.builds.builder",
      "roles/config.admin",
      "roles/storage.admin"
    ]
  }
}

#
# Firestore
#

resource "google_firestore_database" "database" {
  project     = module.system_project.id
  name        = "(default)"
  location_id = "nam5"
  type        = "FIRESTORE_NATIVE"
}

#
# Cloud Run
#

resource "google_artifact_registry_repository" "infra_manager_processor" {
  project       = module.system_project.id
  location      = "us-central1"
  repository_id = "infra-manager-processor"
  description   = "Docker Image repository for infra-manager-processor Cloud Run service"
  format        = "DOCKER"
}

resource "null_resource" "build_image" {
  provisioner "local-exec" {
    command = <<EOT
      cd ${abspath("${path.module}/../../src/infra-manager-processor")}
      gcloud builds submit --project=${module.system_project.id} --tag us-central1-docker.pkg.dev/${module.system_project.id}/${google_artifact_registry_repository.infra_manager_processor.repository_id}/infra-manager-processor
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [google_artifact_registry_repository.infra_manager_processor]
}

module "cloud_run" {
  source     = "../../../fabric-modules/cloud-run-v2"
  project_id = module.system_project.id
  name       = "infra-manager-processor"
  region     = "us-central1"
  containers = {
    hello = {
      image = "us-central1-docker.pkg.dev/${module.system_project.id}/${google_artifact_registry_repository.infra_manager_processor.repository_id}/infra-manager-processor"
      env = {
        PROJECT_ID             = module.system_project.id
        REGION                 = "us-central1"
        ZONE                   = "us-central1a"
        SERVICE_ACCOUNT_NAME   = "sandbox-factory-sa"
        TERRAFORM_BUCKET       = module.terraform_bucket.name
        TERRAFORM_CATALOG_PATH = "catalog"
        TERAFORM_STATE_BUCKET  = module.terraform_state_bucket.name
      }
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  deletion_protection = false

  depends_on = [null_resource.build_image]
}

#
# Cloud Functions
#

resource "google_firebase_project" "default" {
  provider = google-beta
  project  = module.system_project.id

  depends_on = [
    module.system_project
  ]
}

module "deploymentCreated" {
  source      = "../../../fabric-modules/cloud-function-v2"
  project_id  = module.system_project.id
  region      = "us-central1"
  name        = "deploymentCreated"
  bucket_name = "${module.system_project.name}_functions-deploymentcreated"
  bucket_config = {
    location      = "us-central1"
    force_destroy = true
  }
  bundle_config = {
    path = abspath("${path.module}/../../src/firestore-functions")
  }
  environment_variables = {
    GCLOUD_PROJECT = module.system_project.id
    CLOUD_RUN_URL  = module.cloud_run.service_uri
    FIREBASE_CONFIG = jsonencode({
      projectId     = module.system_project.id
      storageBucket = "${module.system_project.id}.firebasestorage.app"
    })
    EVENTARC_CLOUD_EVENT_SOURCE = "projects/${module.system_project.id}/locations/us-central1/services/deploymentcreated"
    FUNCTION_SIGNATURE_TYPE     = "cloudevent"
    FUNCTION_TARGET             = "deploymentCreated"
  }
  function_config = {
    entry_point = "deploymentCreated"
    runtime     = "nodejs22"
  }
  trigger_config = {
    event_type = "google.cloud.firestore.document.v1.created"
    event_filters = [
      {
        attribute = "database"
        value     = "(default)"
      },
      {
        attribute = "document"
        operator  = "match-path-pattern"
        value     = "deployments/{deploymentId}"
      }
    ]
    region = "nam5"
  }

  depends_on = [resource.google_firestore_database.database]
}

module "deploymentUpdated" {
  source      = "../../../fabric-modules/cloud-function-v2"
  project_id  = module.system_project.id
  region      = "us-central1"
  name        = "deploymentUpdated"
  bucket_name = "${module.system_project.name}_functions-deploymentupdated"
  bucket_config = {
    location      = "us-central1"
    force_destroy = true
  }
  bundle_config = {
    path = abspath("${path.module}/../../src/firestore-functions")
  }
  environment_variables = {
    GCLOUD_PROJECT = module.system_project.id
    CLOUD_RUN_URL  = module.cloud_run.service_uri
    FIREBASE_CONFIG = jsonencode({
      projectId     = module.system_project.id
      storageBucket = "${module.system_project.id}.firebasestorage.app"
    })
    EVENTARC_CLOUD_EVENT_SOURCE = "projects/${module.system_project.id}/locations/us-central1/services/deploymentUpdated"
    FUNCTION_SIGNATURE_TYPE     = "cloudevent"
    FUNCTION_TARGET             = "deploymentUpdated"
  }
  function_config = {
    entry_point = "deploymentUpdated"
    runtime     = "nodejs22"
  }
  trigger_config = {
    event_type = "google.cloud.firestore.document.v1.updated"
    event_filters = [
      {
        attribute = "database"
        value     = "(default)"
      },
      {
        attribute = "document"
        operator  = "match-path-pattern"
        value     = "deployments/{deploymentId}"
      }
    ]
    region = "nam5"
  }

  depends_on = [resource.google_firestore_database.database]
}

#
# Budget Management
#

module "budget-topic" {
  source = "../../../fabric-modules/pubsub"

  project_id = module.system_project.id
  name       = "${module.system_project.name}_billing_budget"
}

# NOTE: Billing alerts need to be setup as a post sandbox creation process
# module "billing_alert"  {
#   source = "../../modules/billing-account"
#   id = var.billing_account
#   budgets = {
#     folder-net-month-current-100 = {
#       display_name = "100 dollars in current spend"
#       amount = {
#         units = 100
#       }
#       filter = {
#         period = {
#           calendar = "MONTH"
#         }
#         resource_ancestors = ["folders/1234567890"]
#       }
#       threshold_rules = [
#         { percent = 0.5 },
#         { percent = 0.75 }
#       ]
#       update_rules = {
#         default = {
#           pubsub_topic = module.pubsub-billing-topic.id
#         }
#       }
#     }
#   }
# }
