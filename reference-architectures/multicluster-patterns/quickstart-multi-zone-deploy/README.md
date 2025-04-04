# GKE Multi-Cluster Service Setup and Failover

## Overview

This guide provides a walkthrough of setting up a basic Google Kubernetes Engine
(GKE) infrastructure and demonstrating the capabilities of Multi-Cluster
Services. We will create two zonal GKE clusters, deploy a sample application
(`whereami`) to them, and then configure Multi-Cluster Services to enable
seamless communication between the clusters. The `whereami` application will be
used to illustrate how services can be accessed across cluster boundaries.
Finally, we'll simulate a failure scenario by deleting a backend pod to show how
Multi-Cluster Services facilitates automatic failover, ensuring application
availability.

This setup is ideal for understanding the fundamentals of distributed Kubernetes
deployments on GKE and how Multi-Cluster Services enhances reliability and
resilience.

## Key Concepts Covered

-   GKE Cluster Creation: Provisioning zonal GKE clusters using Terraform.
-   Application Deployment: Deploying a simple frontend/backend application to
    multiple GKE clusters.
-   Multi-Cluster Services (MCS): Configuring and utilizing MCS to enable
    service discovery and access across clusters.
-   Failover Demonstration: Simulating a pod failure to showcase the automatic
    failover capabilities of MCS.

## Prerequisites

-   A Google Cloud project with billing account linked.
-   Terraform: Install Terraform on your local machine or use Cloud Shell.

## Usage

Set project details and authenticate

```sh
export PROJECT_ID=`YOUR PROJECT_ID`

gcloud config set project $PROJECT_ID
gcloud auth application-default login
```

### Enable Required APIs

Replace `YOUR PROJECT_ID` with your Google Cloud project ID.

```sh
gcloud services enable \
  compute.googleapis.com \
    container.googleapis.com \
    multiclusterservicediscovery.googleapis.com \
    gkehub.googleapis.com \
    cloudresourcemanager.googleapis.com \
    trafficdirector.googleapis.com \
    dns.googleapis.com \
  --project=$PROJECT_ID
```

Navigate to the terraform directory and update the terraform.tfvars

```sh
cd multicluster-patterns/quickstart-multi-zone-deploy
```

## Create the Base GKE Infrastructure (Terraform)

You will use Terraform to create:

-   Networking Setup

    -   Creates a custom Google Cloud VPC without auto-subnets.
    -   Defines two specific subnetworks (`10.10.0.0/20` and `10.10.16.0/20`)
        within the VPC and the region specified by `us-central`.

-   GKE Cluster Deployment

    -   Deploys `zonal-cluster-1` in zone `us-central1-a`, utilizing the first
        subnet.
    -   Deploys `zonal-cluster-2` in zone `us-central1-b`, utilizing the second
        subnet.

-   Cluster Configuration (Identical for Both)
    -   Gateway API enabled (Standard Channel).
    -   Workload Identity enabled.
    -   Registered to a Google Cloud Fleet.

```sh
cd terraform
terraform init
terraform apply -var project_id=$PROJECT_ID
```

## Deploy sample application

We will deploy a simple [whereami]
(GoogleCloudPlatform/kubernetes-engine-samples/quickstarts/whereami/README.md)
application consisting of a frontend and a backend to both GKE clusters.

1.  Rename contexts for easy access

    ```sh
    gcloud container clusters get-credentials zonal-cluster-1 \
    --region us-central1-a --project $PROJECT_ID
    kubectl config rename-context "$(kubectl config current-context)" zone-a

    gcloud container clusters get-credentials zonal-cluster-2 \
    --region us-central1-b --project $PROJECT_ID
    kubectl config rename-context "$(kubectl config current-context)" zone-b
    ```

2.  Deploy the sample application to each cluster

    ```sh
    cd ../
    kubectl delete -f manifests/ --context zone-a
    kubectl delete -f manifests/ --context zone-b
    ```

3.  Verify the service is up and running in `zone-a`

    ```sh
    kubectl run temp-curl-client --context zone-b --rm -it \
    --image=curlimages/curl -- /bin/sh
    ```

4.  Execute the curl to see the frontend service running in`zone-a`

    ```sh
    curl http://whereami-frontend.my-app.svc.cluster.local:80
    ```

    This command creates a temporary pod client to access the frontend service
    from inside of the the cluster

    Output should similar to:

    ```json
    {
      "backend_result": {
        "cluster_name": "zonal-cluster-2",
        "gce_instance_id": "5927732544413042383",
        "gce_service_account": "pemulti1.svc.id.goog",
        "host_header": "whereami-backend",
        "metadata": "backend",
        "node_name": "gke-zonal-cluster-2-default-pool-69474490-5t14",
        "pod_ip": "10.68.0.6",
        "pod_name": "whereami-backend-76ff54c56d-xdfr5",
        "pod_name_emoji": "🫙",
        "pod_namespace": "my-app",
        "pod_service_account": "whereami-backend",
        "project_id": "pemulti1",
        "timestamp": "2025-04-04T14:49:26",
        "zone": "us-central1-b"
      },
      "cluster_name": "zonal-cluster-2",
      "gce_instance_id": "5927732544413042383",
      "gce_service_account": "pemulti1.svc.id.goog",
      "host_header": "whereami-frontend.my-app.svc.cluster.local",
      "metadata": "frontend",
      "node_name": "gke-zonal-cluster-2-default-pool-69474490-5t14",
      "pod_ip": "10.68.0.7",
      "pod_name": "whereami-frontend-7f984d8f64-j856n",
      "pod_name_emoji": "🚶🏽‍♀‍➡",
      "pod_namespace": "my-app",
      "pod_service_account": "whereami-frontend",
      "project_id": "pemulti1",
      "timestamp": "2025-04-04T14:49:26",
      "zone": "us-central1-b"
    }
    ```

5.  Attempt accessing the `zone-b` backend from the frontend the `zone-a`
    cluster

    ```sh
    ZONE_B_BACKEND_IP="$(kubectl get po -l app=whereami-backend \
    -n my-app --context zone-b -ojsonpath='{.items[*].status.podIP}')"
    echo ${ZONE_B_BACKEND_IP}

    kubectl run temp-curl-client \
    --image=curlimages/curl -it --rm --pod-running-timeout=4m \
    --context zone-a -- curl -v http://$ZONE_B_BACKEND_IP:80
    ```

Notice you're unable to get the same response as there no connection setup
between the clusters

## Configure multi-cluster Service

[Multi-cluster Services (MCS)]
<https://cloud.google.com/kubernetes-engine/docs/concepts/multi-cluster-services>
enables GKE services to be discovered and accessed across a fleet of VPC-native
clusters using virtual IPs and FQDNs. It configures DNS, firewalls, and health
checks without requiring Anthos licensing or Istio. To use MCS, enable the
feature, register clusters to a fleet, and export services (excluding default
and kube-system namespaces). Clients connect using
SERVICE_EXPORT_NAME.NAMESPACE.svc.clusterset.local.

MultiClusterService (MCS) is a custom resource for multi-cluster Gateways,
representing a service across clusters. It creates derived, headless Services
with NEGs in member clusters based on pod selectors, acting as endpoint groups.
While defaulting to all member clusters, MCS can target specific clusters for
advanced routing scenarios.

1.  Enable multi-cluster-Services in the fleet

    ```sh
    gcloud container fleet multi-cluster-services enable \
        --project $PROJECT_ID
    ```

2.  Grant Identity and Access Management (IAM) permissions required by the MCS
    controller:

    ```sh
    gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$PROJECT_ID.svc.id.goog[gke-mcs/gke-mcs-importer]" \
    --role "roles/compute.networkViewer" \
    --project=$PROJECT_ID
    ```

3.  Confirm that MCS is enabled for the registered clusters. You will see the
    memberships for the three registered clusters. It may take several minutes
    for all of the clusters to show.

    ```sh
    gcloud container fleet multi-cluster-services describe --project=$PROJECT_ID
    ```

    Output should be similar to the follow:

    ```sh
    createTime: '2025-04-02T23:48:38.171804547Z'
    membershipStates:
      projects/807562725141/locations/us-central1/memberships/zonal-cluster-1:
        state:
          code: OK
          description: Firewall successfully updated
          updateTime: '2025-04-02T23:52:35.843646177Z'
      projects/807562725141/locations/us-central1/memberships/zonal-cluster-2:
        state:
          code: OK
          description: Firewall successfully updated
          updateTime: '2025-04-02T23:52:30.629358192Z'
    name: projects/[]/locations/global/features/multiclusterservicediscovery
    resourceState:
      state: ACTIVE
    spec: {}
    updateTime: '2025-04-02T23:48:41.391830411Z'
    ```

4.  Create a [ServiceExport](manifests/mcs/serviceexport.yaml) for both the
    frontend and backend service

    ```sh
    kubectl apply -f manifests/mcs/serviceexport.yaml --context zone-a
    kubectl apply -f manifests/mcs/serviceexport.yaml --context zone-b
    ```

When the ServiceExport resource is created, MCS will automatically perform the
following actions:

-   Configure Cloud DNS zones and records for the exported service. This allows
    clients in other clusters to resolve the service's FQDN to a virtual IP.
-   Configure firewall rules to allow pods on each cluster to communicate with
    each other.

-   Configure Traffic Director resources to enable health checks and endpoint
    information to each cluster.

-   Generate a ServiceImport resource on the other clusters in the fleet

## Test cross cluster access

Now you will attempt to connect from the cluster in `zone-b` from the `zone-a`
cluster

1.  Get the `zone-b` endpoint

    ```sh
    export ZONE_B_BACKEND=$(kubectl get Endpoints whereami-backend -n my-app \
    --context zone-b \
    -o jsonpath='{.subsets[0].addresses[0].ip}:{.subsets[0].ports[0].port}')
    echo $ZONE_B_BACKEND
    ```

2.  Log back into the client pod running in the `zone-a` cluster run the curl
    command on the `zone-b` cluster

    ```sh
    kubectl run temp-curl-client  --context zone-a --rm -it \
    --image=curlimages/curl -- curl http://$ZONE_B_BACKEND
    ```

    Output should be similar to:

    ```json
    {
      "cluster_name": "zonal-cluster-2", # Backend service in(us-central1-b)
      "gce_instance_id": "5927732544413042383",
      "gce_service_account": "pemulti1.svc.id.goog",
      "host_header": "10.68.0.6:8080",
      "metadata": "backend",
      "node_name": "gke-zonal-cluster-2-default-pool-69474490-5t14",
      "pod_ip": "10.68.0.6",
      "pod_name": "whereami-backend-76ff54c56d-xdfr5",
      "pod_name_emoji": "🫙",
      "pod_namespace": "my-app",
      "pod_service_account": "whereami-backend",
      "project_id": "pemulti1",
      "timestamp": "2025-04-03T18:28:17",
      "zone": "us-central1-b" # zone-b
    }
    ```

    The frontend service in `zone-a` cluster can then access the exported
    backend service in the `zone-b` cluster using its Fully Qualified Domain
    Name (FQDN). The format of this FQDN is:
    `[SERVICE_EXPORT_NAME].[NAMESPACE].svc.clusterset.local`

## Testing Failover

Now that we have Multi-Cluster Services (MCS) configured and our `whereami`
application deployed across both clusters, let's simulate a failure scenario.
This will help us observe the automatic failover capabilities.

The goal is to make the backend service in `zone-a` unavailable. We will then
verify that the `zone-a` frontend can still reach a healthy backend instance.
This failover to the `zone-b` backend happens automatically thanks to MCS. We
will achieve this by scaling the backend deployment in `zone-a` down to zero
replicas.

1.  Run a temporary client pod in zone-a within the 'my-app' namespace

    ```sh
    kubectl run temp-curl-client --context zone-a --rm -it \
        --image=curlimages/curl -n my-app -- \
        curl http://whereami-frontend.my-app.svc.cluster.local:80
    ```

2.  Scale down the `whereami-backend` deployment in the `zone-a` cluster to zero
    replicas. This effectively takes the backend service offline.

    ```sh
    kubectl scale deployment whereami-backend --replicas=0 \
    --context zone-a -n my-app
    ```

    Note: Observe the `"cluster_name"` and `"zone"` fields in the JSON output.
    You should see a mix of `zonal-cluster-1`/`us-central1-a` and
    `zonal-cluster-2`/`us-central1-b` responses. This demonstrates load
    balancing.

3.  Confirm that no backend pods are running in `zone-a`.

    ```sh
    kubectl get pods -l app=whereami-backend --context zone-a -n my-app
    ```

    Expected output: `No resources found in my-app namespace.`\*

    Now, run the temporary client pod in `zone-a` again. Attempt to reach the
    backend using the same multi-cluster service address:
    `whereami-backend.my-app.svc.clusterset.local`.

4.  Test Failover from `zone-a` Frontend:

    ```sh
    kubectl run temp-curl-client --context zone-a --rm -it \
    --image=curlimages/curl -n my-app \
    -- curl http://whereami-frontend.my-app.svc.cluster.local:80
    ```

    Observe the Results: Examine the JSON output from the `curl` commands.

    ```json
    {
      "backend_result": {
        "cluster_name": "zonal-cluster-2",
        "gce_instance_id": "5927732544413042383",
        "gce_service_account": "pemulti1.svc.id.goog",
        "host_header": "whereami-backend",
        "metadata": "backend",
        "node_name": "gke-zonal-cluster-2-default-pool-69474490-5t14",
        "pod_ip": "10.68.0.6",
        "pod_name": "whereami-backend-76ff54c56d-xdfr5",
        "pod_name_emoji": "🫙",
        "pod_namespace": "my-app",
        "pod_service_account": "whereami-backend",
        "project_id": "pemulti1",
        "timestamp": "2025-04-04T14:49:26",
        "zone": "us-central1-b"
      },
      "cluster_name": "zonal-cluster-1",
      "gce_instance_id": "3363897077431012570",
      "gce_service_account": "[]-compute@developer.gserviceaccount.com",
      "host_header": "34.58.94.74",
      "metadata": "frontend",
      "node_name": "gke-zonal-cluster-1-default-pool-08f46fa6-t894",
      "pod_ip": "10.68.2.4",
      "pod_name": "whereami-frontend-7f984d8f64-djnh4",
      "pod_name_emoji": "🇫🇮",
      "pod_namespace": "default",
      "pod_service_account": "whereami-frontend",
      "project_id": "test-mcs1",
      "timestamp": "2025-04-02T22:20:36",
      "zone": "us-central1-b"
    }
    ```

    You should consistently see responses only from the backend running in
    `zonal-cluster-2` (`zone-b`). This shows MCS detected the absence of healthy
    backend pods in `zone-a`. It automatically redirected all traffic for
    `whereami-backend.my-app.svc.clusterset.local` to the available instances in
    `zone-b`. The frontend in `zone-a` remains functional by using the backend
    in the other cluster.

5.  Restore Backend in `zone-a`

    To return the system to its original state, scale the backend deployment in
    `zone-a` back up. Let's assume the original replica count was 1 (adjust if
    different).

    ```sh
    kubectl scale deployment whereami-backend --replicas=1 \
    --context zone-a -n my-app
    ```

6.  Verify pods are running again

    ```sh
    kubectl get pods -l app=whereami-backend --context zone-a -n my-app -w
    ```

    Wait for a pod to reach Running state, then press Ctrl+C

After the pod is running and registered as healthy (this may take a minute),
requests to* `whereami-backend.my-app.svc.clusterset.local` should start being
load-balanced across* both clusters again.\*

This test successfully demonstrates the resilience provided by GKE Multi-Cluster
Services. By exporting services, you create a unified service endpoint. This
endpoint automatically routes traffic away from unavailable instances, ensuring
higher availability for your applications spanning multiple clusters.
