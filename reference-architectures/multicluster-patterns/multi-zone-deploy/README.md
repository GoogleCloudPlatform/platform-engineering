# Google Kubernetes Engine (GKE) Multi-Cluster Deployment with Cloud Deploy

This Terraform configuration deploys a multi-cluster GKE setup on Google Cloud Platform (GCP) and configures a Cloud Deploy delivery pipeline for canary deployments across these clusters.

## Overview

The configuration creates the following resources:

* **Two GKE Clusters ("primary" and "secondary"):**
    * Deployed in separate zones (defined by `var.zone_1` and `var.zone_2`).
    * Each cluster has 3 initial nodes.
    * Uses the "RAPID" release channel for GKE.
    * Configures Workload Identity.
    * Enables Gateway API (standard channel).
    * Enables security posture and cost management features.
    * Registers the clusters with a Fleet.
    * Applies resource labels for identification.
    * One cluster has the label "config\_cluster" set to true, the other set to false.
* **GKE Hub Features:**
    * Enables multi-cluster service discovery.
    * Enables  multi-cluster gatewate, with the primary cluster designated as the config membership.
* **Cloud Deploy Targets:**
    * Creates individual targets for the "primary" and "secondary" clusters.
    * Creates a multi-target that combines the primary and secondary targets.
    * The primary target requires approval before deployment.
* **Cloud Deploy Delivery Pipeline:**
    * Creates a delivery pipeline named "pipeline" for canary deployments.
    * The pipeline deploys to the multi-target, which in turn deploys to the primary and secondary clusters.
    * The pipeline uses a canary deployment strategy with percentages of 25%, 50%, and 75%.
    * The pipeline configures service networking for the "store" deployment and service.

## Prerequisites
## Prerequisites

* A Google Cloud project.
* A pre-existing VPC network within your Google Cloud project.
* Terraform installed and configured with appropriate GCP credentials.
* A Git repository containing Kubernetes configurations.
* Variables defined in `terraform.tfvars` or through other means.
* A Google Cloud project with the necessary APIs enabled:
    * Container Registry API
    * Kubernetes Engine API
    * Cloud Deploy API
    * Artifact Registry API
    * GKE Hub API
    * Compute Engine API
* Terraform installed and configured with appropriate GCP credentials.
* A VPC network created and referenced by the `google_compute_network.vpc_network` dependency.
* Variables defined in `terraform.tfvars` or through other means.

## Variables

The following variables are used in the configuration:

* `project_id`: The ID of your Google Cloud project.
* `zone_1`: The zone for the primary GKE cluster.
* `zone_2`: The zone for the secondary GKE cluster.
* `region`: The region for Artifact Registry and Cloud Deploy.
* `cluster_1_name`: The name of the primary GKE cluster.
* `cluster_2_name`: The name of the secondary GKE cluster.

## Usage

1.  **Clone the repository.**
2.  **Configure variables:** Create a `terraform.tfvars` file or use environment variables to set the required variables.
3.  **Initialize Terraform:** Run `terraform init`.
4.  **Plan the deployment:** Run `terraform plan`.
5.  **Apply the configuration:** Run `terraform apply`.

## Dependencies

* `module.enabled_google_apis`: A module to enable required Google Cloud APIs.
* `google_compute_network.vpc_network`: A VPC network resource.

## Notes

* The `depends_on` meta-argument is used to ensure resources are created in the correct order.
* The canary deployment strategy is configured for the "store" service and deployment. You'll need to adjust these values to match your application.
* The primary cloud deploy target requires manual approval.
* This setup assumes a pre-existing VPC network.
* The resource labels are used to distinguish between the primary and secondary clusters.