# Multi-Region Autopilot GKE Enterprise Clusters with Config Sync

This Terraform configuration deploys two Google Kubernetes Engine (GKE) Autopilot clusters in different regions, enabling GKE Enterprise features and configuring Config Sync for GitOps management.

## Overview

This configuration creates the following resources:

* **Two GKE Autopilot Clusters (Region 1 and Region 2):**
    * Deployed in separate regions (defined by `var.region_1` and `var.region_2`).
    * Utilizes GKE Autopilot for automated node management.
    * Enables GKE Enterprise features.
    * Configures Workload Identity.
    * Enables Config Sync for GitOps.
    * registers the clusters with a fleet.
* **GKE Hub Feature Membership:**
    * Registers both clusters to a fleet.
* **Config Sync Configuration:**
    * Configures Config Sync to synchronize configurations from a specified Git repository.

## Prerequisites

* A Google Cloud project.
* A pre-existing VPC network within your Google Cloud project.
* Terraform installed and configured with appropriate GCP credentials.
* A Google Cloud project with the necessary APIs enabled:
    * Kubernetes Engine API
    * GKE Hub API
    * Cloud Resource Manager API
    * Config Management API
* Terraform installed and configured with appropriate GCP credentials.
* A Git repository containing Kubernetes configurations.
* Variables defined in `terraform.tfvars` or through other means.

## Variables

The following variables are used in the configuration:

* `project_id`: The ID of your Google Cloud project.
* `region_1`: The first region for the GKE Autopilot cluster.
* `region_2`: The second region for the GKE Autopilot cluster.
* `cluster_name_1`: The name of the first GKE Autopilot cluster.
* `cluster_name_2`: The name of the second GKE Autopilot cluster.
* `git_repo`: The URL of the Git repository for Config Sync.
* `git_branch`: The branch to synchronize from the Git repository.
* `git_dir`: The directory within the Git repository to synchronize.

## Usage

1.  **Clone the repository.**
2.  **Enable Required APIs:**
    * Replace `PROJECT_ID` with your Google Cloud project ID.
    * Run the following command in your terminal:

    ```bash
    gcloud services enable \
      trafficdirector.googleapis.com \
      multiclusterservicediscovery.googleapis.com \
      multiclusteringress.googleapis.com \
      --project=PROJECT_ID
    ```