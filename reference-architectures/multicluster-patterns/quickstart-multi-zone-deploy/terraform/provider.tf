
 terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.25.0"
    }
  }

  provider_meta "google-beta" {
    module_name = "cloud-solutions/platform-engineering-multipattern-zonal-mcs-mcg-v1"
  }
}
provider "google" {
  project = var.project_id
}

