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

1.  Set project details and authenticate

    ```sh
    export PROJECT_ID=`YOUR PROJECT_ID`
    export LOCATION=us-central1
    export ZONE_1=us-central1-a
    export ZONE_2=us-central1-b
    gcloud config set project $PROJECT_ID
    gcloud auth application-default login
    ```

1.  Enable Required APIs:**
    * Replace `YOUR PROJECT_ID` with your Google Cloud project ID.
    * Run the following command in your terminal:

    ```sh
    gcloud services enable \
      aartifactregistry.googleapis.com \
      compute.googleapis.com \
      container.googleapis.com \
      clouddeploy.googleapis.com \
      cloudbuild.googleapis.com \
      gkehub.googleapis.com \
      trafficdirector.googleapis.com \
      multiclusterservicediscovery.googleapis.com \
      multiclusteringress.googleapis.com \
      --project=$PROJECT_ID
    ```

1.  Verify VPC network exists

    ```sh
    gcloud compute networks list
    ```

1.  Navigate to the terraform directory and update the terraform.tfvars

    ```sh
    cd multicluster-patterns/quickstart-multi-zone-deploy/terraform
    ```

1.   Create resources

```sh
terraform init
terraform apply -var-file=terraform.tfvars
```

1. Confirm GKE Gateway controller is enabled

```sh
gcloud container fleet ingress describe --project=$PROJECT_ID
```

Output should be similar to

```sh
createTime: '2025-03-19T18:18:04.666230169Z'
labels:
  goog-terraform-provisioned: 'true'
membershipStates:
  projects/230886647806/locations/us-central1/memberships/primary-cluster:
    state:
      code: OK
      updateTime: '2025-03-19T18:21:22.400361055Z'
  projects/230886647806/locations/us-central1/memberships/secondary-cluster:
    state:
      code: OK
      updateTime: '2025-03-19T18:21:22.400361885Z'
name: projects/pe-multi-cluster-zonal22/locations/global/features/multiclusteringress
resourceState:
  state: ACTIVE
spec:
  multiclusteringress:
    configMembership: projects/pe-multi-cluster-zonal22/locations/us-central1/memberships/primary-cluster
state:
  state:
    code: OK
    description: Ready to use
    updateTime: '2025-03-19T18:19:04.605677961Z'
updateTime: '2025-03-19T18:21:23.771948904Z'
```

## Deploy sample application

Build the sample app located it the `app` folder

```sh
./setup.sh
```
