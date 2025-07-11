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

resource "local_file" "namespace_yaml" {
  content = templatefile(
    "${path.module}/manifests/templates/namespace.tftpl.yaml",
    {
      namespace = "backstage"
    }
  )
  filename = "./manifests/k8s/namespace.yaml"
}

resource "local_file" "service_yaml" {
  content = templatefile(
    "${path.module}/manifests/templates/service.tftpl.yaml",
    {
      deployment_name = "backstage"
      namespace       = "backstage"
      service_name    = "backstage"
      service_port    = 80
    }
  )
  filename = "./manifests/k8s/service.yaml"
}

resource "local_file" "deployment_yaml" {
  content = templatefile(
    "${path.module}/manifests/templates/deployment.tftpl.yaml",
    {
      cloud_sql_name       = google_sql_database_instance.instance.connection_name
      deployment_name      = "backstage"
      namespace            = "backstage"
      postgres_port        = 5432
      postgres_db          = "backstage"
      postgres_user        = trimsuffix(google_service_account.workloadSa.email, ".gserviceaccount.com")
      service_account_name = "ksa-backstage"
    }
  )
  filename = "./manifests/k8s/deployment.yaml"
}
