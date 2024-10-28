# Platform Engineering Deployment Demo

## Background

Platform engineering focuses on providing a robust framework for managing the deployment of applications across various environments. One of the critical components in this field is the automation of application deployments, which streamlines the entire process from development to production.

This demo showcases a complete workflow that begins with the build of a container and progresses through various stages, ultimately resulting in the deployment of a new application.

## Overview of the Demo

This demo illustrates the end-to-end deployment process, starting from the container build phase. Here's a high-level overview of the workflow:

1. **Container Build Process**: The demo begins when a container is built in Cloud Build. Upon completion, a notification is sent to a Pub/Sub message queue.

2. **Release Logic**: A Cloud Function subscribes to this message queue, assessing whether a release should be created. If a release is warranted, a message is sent to a "Command Queue" (another Pub/Sub topic).

3. **Creating a Release**: A dedicated function listens to the "Command Queue" and communicates with Cloud Deploy to create a new release. Once the release is created, a notification is dispatched to the Pub/Sub Operations topic.

4. **Rollout Process**: Another Cloud Function picks up this notification and initiates the rollout process by sending a `createRolloutRequest` to the "Command Queue."

5. **Approval Process**: Since rollouts typically require approval, a notification is sent to the `cloud-deploy-approvals` Pub/Sub queue. An approval function then picks up this message, allowing you to implement your custom logic or utilize the provided Website Demo to return JSON, such as `{ "manualApproval": "true" }`.

6. **Deployment**: Once approved, the rollout proceeds, and the new application is deployed.

![Workflow Diagram](insert-link-to-svg-here)

## Getting Started

To run this demo, follow these steps:

1. **Initialize Terraform**: 
   ```
   terraform init
   ```
2. **Apply Terraform Configuration**:
    ```
    terraform apply
    ```
3. **Connecting Github Repo**:
    You may encounter issues when connecting your GitHub repository to Cloud Build. You will need to manually attach the repository to Cloud Build.
## Conclusion

This demo encapsulates the essential components and workflow for deploying applications using platform engineering practices. It illustrates how various services interact to ensure a smooth deployment process.