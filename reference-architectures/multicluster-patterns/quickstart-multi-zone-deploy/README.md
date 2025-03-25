# Google Kubernetes Engine (GKE) Multi-Cluster Deployment with Cloud Deploy

This Terraform configuration deploys a multi-cluster GKE setup on Google Cloud
Platform (GCP) and configures a Cloud Deploy delivery pipeline for canary
deployments across these clusters.

## Prerequisites

*   A Google Cloud project.
*   Terraform installed and configured with appropriate GCP credentials.
*   Variables defined in `terraform.tfvars` or through other means.

## Usage

Set project details and authenticate

```sh
export PROJECT_ID=`YOUR PROJECT_ID`
export LOCATION=us-central1

gcloud config set project $PROJECT_ID
gcloud auth application-default login
```

### Enable Required APIs

Replace `YOUR PROJECT_ID` with your Google Cloud project ID.

```sh
gcloud services enable \
  artifactregistry.googleapis.com \
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

Navigate to the terraform directory and update the terraform.tfvars

```sh
cd multicluster-patterns/quickstart-multi-zone-deploy
```

Create resources

```sh
cd terraform
terraform init
terraform apply -var-file=terraform.tfvars -var project_id=$PROJECT_ID
```

Confirm GKE Gateway controller is enabled

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
name: projects/[PROJECT]/locations/global/features/multiclusteringress
resourceState:
  state: ACTIVE
spec:
  multiclusteringress:
    configMembership: projects/[PROJECT]/locations/us-central1/memberships/
    primary-cluster
state:
  state:
    code: OK
    description: Ready to use
    updateTime: '2025-03-19T18:19:04.605677961Z'
updateTime: '2025-03-19T18:21:23.771948904Z'
```

Confirm the Gateway exists in the config cluster

```sh
gcloud container clusters get-credentials config-cluster --region us-central1-a
kubectl get gatewayclasses
```

## Deploy sample application

Build the sample app located it the `app` folder and store the image in
Artifact Registry and Deploy the k8s objects in the `manifest` folder
to the clusters

The manifest folder contains the Deployment, Services, ServiceExports, Gateway
and HTTPRoute objects

```sh
export VIP=$(kubectl get gateways.gateway.networking.k8s.io app-gateway \
      -o=jsonpath="{.status.addresses[*].value}" \
      --context gke_${PROJECT_ID}_${ZONE_1}_primary-cluster \
      --namespace myapp)

echo http://$VIP
```

Output will include the external IP to access the application

```sh
http://34.8.69.82/
```
