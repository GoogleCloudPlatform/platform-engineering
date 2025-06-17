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

resource "google_sql_database_instance" "instance" {
  name                = var.cloudsql_instance_name
  project             = var.environment_project_id
  region              = var.region
  database_version    = "POSTGRES_15"
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
    ip_configuration {
      ipv4_enabled = false
      psc_config {
        psc_enabled               = true
        allowed_consumer_projects = [var.environment_project_id]
      }
      ssl_mode = "ENCRYPTED_ONLY"
    }
  }
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "google_sql_database" "database" {
  name     = "backstage"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "iam_service_account_user" {
  # Note: for Postgres only, GCP requires omitting the ".gserviceaccount.com" suffix
  # from the service account email due to length limits on database usernames.
  
  name     = trimsuffix(google_service_account.workloadSa.email, ".gserviceaccount.com")
  instance = google_sql_database_instance.instance.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
}

resource "null_resource" "sqlIamDelay" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
  triggers = {
    "before" = "${google_sql_database_instance.instance.id}"
  }
}

data "template_file" "app_config_production" {
  template = "${file("./manifests/app-config.production.yaml")}"
  vars = {
    POSTGRES_HOST = google_sql_database_instance.instance.dns_name
    POSTGRES_PORT = 5432
    POSTGRES_DB = "backstage"
    POSTGRES_USER = trimsuffix(google_service_account.workloadSa.email, ".gserviceaccount.com")
  }
}

resource "null_resource" "local" {
  # triggers {
  #   template = "${data.template_file.test.rendered}"
  # }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.app_config_production.rendered}\" > ./manifests/app-config.production.yaml.rendered"
  }
}
