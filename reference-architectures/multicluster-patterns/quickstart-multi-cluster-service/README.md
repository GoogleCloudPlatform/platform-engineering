# GKE Multi-Cluster Blue/Green Deployment for Resilient Applications

This document guides you through setting up a resilient application deployment
across multiple Google Kubernetes Engine (GKE) clusters using Multi-Cluster
Services (MCS) and a blue/green deployment strategy managed by Google Cloud
Deploy. This approach enhances application availability and minimizes downtime
during updates.

## Objectives

This setup demonstrates:

-   Provisioning zonal GKE clusters using Terraform.
-   Deploying a sample application to multiple GKE clusters.
-   Configuring and utilizing Multi-Cluster Services (MCS) to enable
    cross-cluster service discovery and load balancing.
-   Performing a blue/green deployment using Google Cloud Deploy to manage the
    rollout process.
-   Simulating pod failure (implicitly addressed by MCS load balancing) to
    showcase automatic failover capabilities.
-   Understanding how MCS enhances application resilience, especially within a
    blue/green deployment scenario.

## Key Concepts

-   **GKE Cluster Creation**: Using Terraform to automate the provisioning of
    zonal GKE clusters ensures reproducible infrastructure.
-   **Application Deployment**: Deploying a simple frontend/backend application
    to multiple GKE clusters serves as the workload for verifying cross-cluster
    connectivity and deployment strategies.
-   **Multi-Cluster Services (MCS)**: Configuring and utilizing MCS enables
    seamless service discovery and access across registered GKE clusters within
    a Fleet. MCS abstracts networking complexities, allowing services in one
    cluster to be discovered and consumed by applications in others using a
    common DNS name (`<service>.<namespace>.svc.clusterset.local`).
-   **Failover Demonstration**: MCS inherently provides load balancing across
    healthy endpoints in participating clusters. If pods in one cluster fail,
    MCS automatically directs traffic to healthy pods in other clusters,
    demonstrating improved resilience.
-   **Blue/Green Deployment**: A deployment strategy that minimizes downtime and
    risk during application updates. A new version ("blue") is deployed
    alongside the existing version ("green"). Traffic is gradually shifted (or
    switched) to the blue environment once it's verified. Cloud Deploy
    orchestrates this process across clusters.
-   **Resilience**: Understanding how the combination of multiple clusters, MCS
    for cross-cluster load balancing/failover, and controlled blue/green
    rollouts significantly enhances an application's ability to withstand
    failures and remain available.

### Terminology

| Term           | Definition                                                 |
| :------------- | :--------------------------------------------------------- |
| ServiceExport  | User object exporting a K8s Svc across clusters.           |
| ServiceImport  | Auto-created object for an imported service.               |
| Endpoints      | Auto-created list of backend pods for exported Svc.        |
| DerivativeSvc  | Auto-created ClusterIP Svc for local Import access.        |
| MCS Importer   | Auto-deployed workload updating Endpoints via TD.          |
| MCS Hub Ctrl   | Manages resources (Import, DNS, TD) for Exports.           |
| Traffic Dir    | GCP service sending multi-cluster config via xDS.          |
| Cloud DNS Zone | Regional private DNS (`clusterset.local`) for Svc records. |

## Prerequisites

-   A Google Cloud Project with billing enabled.
-   Familiarity with Kubernetes, GKE, and basic networking concepts.
-   Google Cloud SDK (`gcloud` command-line tool) installed and configured.
-   `kubectl` command-line tool installed.
-   Terraform installed.
-   Git installed.
-   Docker installed and running (or another container build tool).

## Setting up the Google Cloud Environment

This section guides you through setting up the necessary Google Cloud
environment variables and authentication.

1.  **Set environment variable** Define environment variables for your Project
    ID and the default region for resource creation.

    ```sh
    export PROJECT_ID="your-project-id"
    export REGION="us-central1"
    export PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" \
    --format="value(projectNumber)")
    echo "Project Number: ${PROJECT_NUMBER}"
    gcloud config set project "${PROJECT_ID}"
    ```

2.  **Authenticate:** Authenticate the Google Cloud SDK to allow it to manage
    resources on your behalf.

    ```sh
    gcloud auth application-default login
    ```

3.  Enable the necessary APIs for:

    -   GKE
    -   GKE Hub (Fleet management)
    -   Multi-cluster Service
    -   Compute Engine
    -   Cloud Build
    -   Artifact Registry,
    -   Cloud Deploy.

    ```sh
    gcloud services enable \
        compute.googleapis.com \
        container.googleapis.com \
        gkehub.googleapis.com \
        cloudresourcemanager.googleapis.com \
        trafficdirector.googleapis.com \
        multiclusterservicediscovery.googleapis.com \
        multiclusteringress.googleapis.com \
        cloudbuild.googleapis.com \
        artifactregistry.googleapis.com \
        clouddeploy.googleapis.com \
        --project=$PROJECT_ID
    ```

## Create the Base GKE Infrastructure (Terraform)

You will use Terraform to create:

-   Networking Setup

    -   Creates a custom Google Cloud VPC with auto-subnets.

-   GKE

    -   Create clusters:
    -   `gke-1` in zone `us-west1-a`
    -   `gke-2` in zone `us-west1-b`
    -   [Cloud DNS][cloud-dns] enabled on all clusters
    -   Enable the GKE API on all clusters
    -   Enable [Workload Identity][workload-identity] on all cluster
    -   Create a Fleet and register all clusters to the fleet
    -   Enables a `Multicluster Service Discovery` and `Multicluster Ingress`

Use Terraform to provision the GKE clusters, configure GKE Hub Fleet membership,
and set up other required resources like Artifact Registry.

1.  Deploy the necessary infrastructure

    ```sh
    cd terraform
    terraform init
    terraform apply -var project_id=$PROJECT_ID
    cd ../
    ```

2.  Confirm that the clusters have been successfully registered to the fleet

    ```sh
    gcloud container fleet memberships list --project=$PROJECT_ID
    ```

    The output will be similar to the following:

    ```sh
    NAME   UNIQUE_ID                             LOCATION
    gke-2  4ff62f84-bc3e-4bd2-b77b-c1c16ad8bc5b  us-central1
    gke-1  0b7fd8bb-a1ad-4ba2-8c07-3b74d52c20ac  us-central1
    ```

3.  Grant Identity and Access Management (IAM) permissions required by the MCS
    controller and multi-cluster Gatewaycontroller

    ```sh
    gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$PROJECT_ID.svc.id.goog[gke-mcs/gke-mcs-importer]" \
    --role "roles/compute.networkViewer" \
    --project=$PROJECT_ID
    ```

4.  Get Cluster Credentials and Set Contexts: Fetch credentials for each cluster
    and rename the contexts for clarity. Name them green and blue corresponding
    to our deployment strategy phases.

    ```sh
    gcloud container clusters get-credentials gke-1 \
    --zone ${REGION}-a --project "${PROJECT_ID}"
    kubectl config rename-context "gke_${PROJECT_ID}_${REGION}-a_gke-1" green


    gcloud container clusters get-credentials gke-2 \
    --zone ${REGION}-b --project "${PROJECT_ID}"
    kubectl config rename-context "gke_${PROJECT_ID}_${REGION}-b_gke-2" blue
    ```

## Deploy the sample application

Build the sample whereami application's Docker image and push it to the Artifact
Registry repository created by Terraform.

1.  Configure Docker Authentication: Allow Docker to authenticate with Artifact
    Registry using gcloud credentials.

    ```sh
    gcloud auth configure-docker "${REGION}-docker.pkg.dev"
    ```

2.  Build and Push Image: Navigate to the application directory, build the
    image, tag it, and push it.

    ```sh
    docker build -t us-docker.pkg.dev/$PROJECT_ID/my-repo/app ./app
    docker push us-docker.pkg.dev/$PROJECT_ID/my-repo/app:latest
    ```

3.  Apply Deployment to both cluster

    ```sh
    envsubst < ./k8s/deployment.yaml.tpl | kubectl apply --context blue -f -
    envsubst < ./k8s/deployment.yaml.tpl | kubectl apply --context green -f -
    ```

4.  Verify rollout stat

    ```sh
    kubectl get deployments -n app --context green
    kubectl get deployments -n app --context blue
    ```

    wait for the deployment to become `Ready`

5.  Retrieve the internal ClusterIP addresses of the myapp service for each
    cluster.

    ```sh
    GREEN_SVC_IP=$(kubectl get service myapp -n app \
    --context=green -o jsonpath='{.spec.clusterIP}') && \
    kubectl run curl-client \
        --image=curlimages/curl:latest -n app --context=green \
        --restart=Never -it --rm -- curl -v -m 10 http://${GREEN_SVC_IP}:8080
    ```

    Example output:

    ```sh
    Hello World!
    ```

6.  Test connecting to the blue cluster from within the green cluster

    ```sh
    BLUE_SVC_IP=$(kubectl get service myapp -n app \
    --context=blue -o jsonpath='{.spec.clusterIP}') && \
    kubectl run curl-client \
    --image=curlimages/curl:latest -n app --context=green \
    --restart=Never -it --rm -- curl -v -m 10 http://${BLUE_SVC_IP}:8080
    ```

    Example output:

    ```sh
    * Connection timed out after 10002 milliseconds
    * closing connection #0
    curl: (28) Connection timed out after 10002 milliseconds
    pod "curl-client" deleted
    pod app/curl-client terminated (Error)
    ameenahb@ameenahb:~/development/platform
    ```

    In the examples you will see the response from the green cluster, to the
    blue cluster times out.

## Configure multi-cluster Service

In this section we will deploy [Multi-cluster Services
(MCS)][multi-cluster-services] CRD `Service Exports` to each of the clusters.
MCS enable GKE services to be discovered and accessed across a fleet of
VPC-native clusters using virtual IPs and FQDNs without requiring Anthos
licensing or Istio.

To use MCS enable the feature:

-   Ensure the clusters are part of a fleet. Note: This was enabled in the
    terraform setup.
-   Create a ServiceExport custom resource using the same namespace and name as
    the Service (excluding default and kube-system namespaces).
-   Connect to services using
    `SERVICE_EXPORT_NAME.NAMESPACE.svc.**clusterset**.local.`

1.  Confirm that the clusters have been successfully registered to the fleet:

    ```sh
    gcloud container fleet memberships list --project=$PROJECT_ID
    ```

    The output will be similar to the following:

    ```sh
    NAME   UNIQUE_ID                             LOCATION
    gke-2  4ff62f84-bc3e-4bd2-b77b-c1c16ad8bc5b  us-central1
    gke-1  0b7fd8bb-a1ad-4ba2-8c07-3b74d52c20ac  us-central1

    ```

2.  Grant Identity and Access Management (IAM) permissions required by the MCS
    controller and multi-cluster Gatewaycontroller:

    ```sh
    gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$PROJECT_ID.svc.id.goog[gke-mcs/gke-mcs-importer]" \
    --role "roles/compute.networkViewer" \
    --project=$PROJECT_ID
    ```

    > Note the multicluster serivce was enabled in the terraform setup. To
    > enable the multicluster service on a fleet, use the following command

    ```sh
    gcloud container fleet multi-cluster-services enable \
    --project $PROJECT_ID
    ```

3.  Create a `ServiceExport` for both the frontend and backend service

    ```sh
    kubectl apply -f k8s/serviceexport.yaml --context green
    kubectl apply -f k8s/serviceexport.yaml --context blue
    ```

4.  After applying the `ServiceExport`, let's verify that the MCS components are
    running and reacting as expected.

    ```sh
    kubectl get deployments --all-namespaces \
    --context=blue | grep -v "kube-system" | grep -v "gmp-system"
    ```

    The output will be similar to the following:

    ```sh
    NAMESPACE     NAME                            READY   UP-TO-DATE   AVAILABLE
    app           myapp                           1/1     1            1
    gke-mcs       gke-mcs-importer                1/1     1            1

    ```

5.  After a few minutes verify the ServiceImport was created

    ```sh
    kubectl get serviceimports --context blue --namespace app
    kubectl get serviceimports --context green --namespace app
    ```

    > Note: The first MCS you create in your fleet can take up to 20 min to be
    > fully operational. Exporting new services after the first one is created
    > or adding endpoints to existing Multi-cluster Services is faster (up to a
    > few minutes in some cases).

## Exploring Multi-Cluster Services (MCS) Resources and Connectivity

1.  Examine the MCS logs The gke-mcs-importer (or a similarly named component in
    other MCS implementations) is responsible for watching ServiceExport
    resources. Checking its logs can confirm it has recognized the export and is
    managing discovery zones. Look for messages indicating updates to watched
    zones.

    ```sh
    kubectl logs -n gke-mcs -l k8s-app=gke-mcs-importer \
    --context=blue
    ```

    Output:

    ```sh
    Update from us-central1-a with 2 negs
    Update from us-central1-b with 2 negs
    ```

    In the response you will see that both zones have corresponding negs created
    This will allow the cluster to communcate with each other.

2.  Examine the `ServiceImport`

    ```sh
    kubectl get ServiceImport myapp -n app -o yaml --context=blue
    ```

    Output:

    ```sh
    apiVersion: v1
    items:
    - apiVersion: net.gke.io/v1
    kind: ServiceImport
    metadata:
        annotations:
        net.gke.io/derived-service: gke-mcs-1a8qqpah56
        creationTimestamp: "2025-04-01T18:03:06Z"
        generation: 3
        labels:
        app.kubernetes.io/managed-by: gke-mcs-controller.gke.io
        net.gke.io/backend-service-name: gkemcs-app-myapp
        net.gke.io/export-network: gke-vpc
        net.gke.io/export-project: "680206487583"
        name: myapp
        namespace: app
        resourceVersion: "46486"
        uid: 7fa935e7-8d6a-44b3-a624-a0927324feef
    spec:
        ips:
        - 34.118.229.70
        ports:
        - port: 8080
        protocol: TCP
        sessionAffinity: None
        type: ClusterSetIP
    status:
        clusters:
        - cluster: projects/680206487583/locations/us-central1/memberships/gke-1
        - cluster: projects/680206487583/locations/us-central1/memberships/gke-2
    ```

    The ServiceImport provides a stable abstraction. Applications within any
    cluster can discover and interact with this ServiceImport without needing to
    know which specific cluster(s) are currently hosting the backend pods. This
    simplifies client configuration compared to alternatives where clients might
    need different endpoints depending on which cluster they target or manually
    handle failover.

3.  Get the MCS Service's `Endpoints` created

    ```sh
    # Check Endpoints on the blue cluster
    kubectl get Endpoints -n app --context=blue

    # Check Endpoints on the green cluster
    kubectl get Endpoints -n app --context=green
    ```

    Example output

    ```sh
    NAME                 ENDPOINTS                           AGE
    gke-mcs-1a8qqpah56   10.188.0.16:8080,10.196.1.13:8080   138m
    myapp                10.196.1.13:8080                    145m

    ```

    Interpreting the Output:

    Notice two Endpoints objects related to myapp:

    -   **myapp**: This is the standard one, showing only local pod IPs for that
        cluster (e.g., 10.188.0.16:8080 on blue, 10.196.1.13:8080 on green).
    -   **gke-mcs-xxxx**: This is the MCS-managed one. It lists the pod IPs from
        both clusters (10.188.0.16:8080,10.196.1.13:8080). You'll see this same
        aggregated list on both the blue and green clusters. This consistent,
        fleet-wide view of endpoints enables seamless cross-cluster
        communication.

4.  Test Connectivity via MCS DNS

    ```sh
    kubectl run curl-client --image=curlimages/curl:latest -n app \
    --context=green --restart=Never -it --rm \
    -- curl -v -m 10 myapp.app.svc.clusterset.local:8080
    ```

    Output:

    ```sh
    Hello World!
    ```

    MCS enables service discovery is through DNS. It automatically creates DNS
    records. A client pod running in any cluster within the fleet can use this
    exact same DNS name `service-name.namespace.svc.clusterset.local`.

## Building and pushing application updates using Cloud Build

Building container images and deploying applications involves several steps. To
ensure consistency and reliability when building your application container
after code changes, you can automate the process using [Cloud
Build][cloud-build].

1.  Make an update the the application. Open the [main.py](app/main.py) file and
    make an update to `hello_world()`

2.  Understand the Cloud Build Configuration (cloudbuild.yaml).

    ```sh
    cat cloudbuild.yaml
    gcloud builds submit --config=cloudbuild.yaml \
    --substitutions=_TAG=v1.1
    ```

    The cloudbuild.yaml file contains insturctions to build the container using
    Docker and store the updated image in Artifact Registry.

## Cloud Deploy blue/Green deployment strategy

To push the updates to GKE and update the change across the clusters, we will
use[Cloud Deploy][cloud-deploy]. Cloud Deploy automates and standardizes this
process. Configuring pipelines and target environments (clusters) declaratively,
allows Cloud Deploy to orchestrate rollout, approval steps and rollbacks.

In this section, you will configure Cloud Deploy and use it to perform a
blue/green update of the multi-cluster myapp service.

1.  Enable the Cloud Deploy API for your project.

    ```sh
    gcloud services enable clouddeploy.googleapis.com --project=$PROJECT_ID
    ```

2.  Grant the Cloud Deploy service agent the necessary permissions

    ```sh
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
        --format="value(projectNumber)")-compute@developer.gserviceaccount.com \
        --role="roles/clouddeploy.jobRunner" &&
    gcloud iam service-accounts add-iam-policy-binding \
    $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role="roles/iam.serviceAccountUser" \
    --project=$PROJECT_ID
    ```

3.  Apply the Cloud Deploy delivery pipeline configuration

    ```sh
    gcloud deploy apply --file=deploy/pipeline.yaml --region=$REGION
    ```

    This YAML file defines the workflow for deploying your application:

    ```sh
    apiVersion: deploy.cloud.google.com/v1
    kind: DeliveryPipeline
    metadata:
    name: bluegreen-pipeline
    description: main application pipeline
    serialPipeline:
    stages:
    - targetId: blue-target
    profiles:
    - blue
    deployParameters:
    - values:
        replicaCount: "1"
        color: "blue"
    - targetId: green-target
    profiles:
    - green
    deployParameters:
    - values:
        replicaCount: "1"
    ```

    -   serialPipeline: This specifies that the stages defined within it will
        execute sequentially, one after the other. When one stage completes
        successfully, the next one begins (or waits for promotion/approval if
        configured).
    -   stages: This array defines the sequence of deployment steps.
        -   Stage 1:
            -   targetId: blue-target: This stage deploys to the target named
                blue-target (which should be defined in your targets.yaml file
                and point to your blue GKE cluster).
            -   profiles: [blue]: Specifies that the Skaffold profile named blue
                should be activated for this stage. Skaffold profiles allow you
                to define variations in your build and deploy configuration
                (e.g., using different Kubernetes manifest customizations via
                Kustomize or Helm).
            -   deployParameters: These key-value pairs (replicaCount, color)
                are passed to the Skaffold rendering process. You can use these
                parameters within your Kubernetes manifests (e.g., with Helm
                templating ${values.color} or Kustomize) to customize the
                deployment for the blue stage specifically. Note: Deploy
                parameter values are typically expected as strings.
        -   Stage 2:
            -   targetId: green-target: This stage deploys to the green-target
                (your green GKE cluster).
            -   profiles: [green]: Activates the green Skaffold profile.
            -   deployParameters: Provides parameters (replicaCount, color)

4.  Replace variables in [deployment.yaml.tpl](k8s/deployment.yaml.tpl) with
    deploy parameters that work with Cloud Deploy as substituation variables.

    ```sh
    cp k8s/deployment.yaml.tpl k8s/deployment.yaml
    ```

5.  In the newly create [deployment.yaml](k8s/deployment.yaml)

    Update the image from..
    `image: us-docker.pkg.dev/${PROJECT_ID}/my-repo/app:latest`

    to.. `my-app-image`

    This allows passing the image the container will using in the gcloud deploy
    parameter.

    > Note: You can also pass parameters as part of the

        [pipeline configurations](deploy/pipeline.yaml) using deployparameters
        `replicas: 1 #from-param: ${replicaCount}` - will update the number of
        replicas with the value set in the pipeline configurations

6.  Create the first Cloud Deploy release for the Kubernetes Deployment
    manifest.

    ```sh
    RELEASE_1=$RANDOM
    gcloud deploy releases create app-release-$RELEASE_1 \
        --project=$PROJECT_ID \
        --region=$REGION \
        --delivery-pipeline=bluegreen-pipeline \
        --from-k8s-manifest=./k8s/deployment.yaml
    ```

    This command initiates a new deployment process. A release in Cloud Deploy
    is an immutable snapshot of your application's configuration (in this case,
    the k8s/deployment.yaml manifest).

7.  Review the changes to the application

    ```sh
    kubectl run curl-client --image=curlimages/curl:latest -n app \
    --context=green --restart=Never -it --rm \
    -- curl -v -m 10 myapp.app.svc.clusterset.local:8080
    ```

## Clean up

```sh
  terraform init
  terraform plan -var "project_id=$PROJECT_ID"
  terraform destroy -var "project_id=$PROJECT_ID" --auto-approve
```

## Conclusion

This tutorial demonstrated Multi-Cluster Services to deploy an application
across GKE clusters. Integrating Cloud Build for automated container builds and
Google Cloud Deploy for orchestrating blue/green updates, you implemented a
repeatable process for managing application rollouts. Combining these Google
Cloud services for building highly resilient applications that can handle
updates and potential failures gracefully across multiple clusters.
