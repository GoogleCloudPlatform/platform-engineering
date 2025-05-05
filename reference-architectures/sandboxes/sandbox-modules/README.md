# Sandbox Projects

# Data Model

## Deployment

| Field | Type | Description
| ----- | ---- | -----------
| `_updateSource`               | string        | This describes the last process or tool used to update or create the deployment document. For example, the example python cli `_updateSource` is set to `python` and when the `firestore-processor` Cloud Run updates the document it is set to `cloudrun`.
| `status`                      | string        | Status of the sandbox, this changes create and delete operations progress. Refer to [Key Statuses](#key-statuses) for detailed definitions of the values.
| `projectId`                   | string        | The project id of the sandbox.
| `templateName`                | string        | The name of the Terraform template from the catalog that the sandbox is based on.
| `deploymentState`             | object<[DeploymentState](#deploymentstate)> | State object for the sandbox deployment. Contains data such as budget, current spend, expiration date, etc.The state object is updated by and used by the various lifecycle functions.
| `infraManagerDeploymentId`    | string        | Id returned by [Infrastructure Manager][infra-manager] for the deployment.
| `infraManagerResult`          | object<[DeploymentResponse][inframanager-deployment]> |
| `userId`                      | string        | Unique identifier for the user which owns the sandbox deployment.
| `createdAt`                   | string        | Timestamp that the sandbox record was created at.
| `updatedAt`                   | string        | Timestamp that the sandbox record was last updated.
| `variables`                   | object<[Variables](#variables)> | List of variable supplied by the user, which are in turned used by the template to create the sandbox.
| `auditLog`                    | array[string] | List of messages that the system can add as an audit log.

## DeploymentState

| Field | Type | Description
| ----- | ---- | -----------
| `budgetLimit`     | number | Spend limit for the sandbox.
| `currentSpend`    | number | Current spend for the sandbox.
| `expiresAt`       | string | Time base expiration for the sandbox.


## Key Statuses

The following table describes important statuses that are used during the lifecycle of a deployment.

| Status | Set By | Handled By | Meaning
| ------ | ------ | ---------- | -------
| `provision_requested`     | User Interface            | `firestore-functions`     | The user has requested that a sandbox be provisioned.
| `provision_pending`       | `infra-manager-processor` | `infra-manager-processor` | Indicates the request was received by the `infra-manager-processor` but the request hasn’t yet been made to Infrastructure Manager.
| `provision_inprogress`    | `infra-manager-processor` | `infra-manager-processor` | Indicates that the request has been submitted to Infrastructure Manager and it is in progress with Infrastructure Manager.
| `provision_error`         | `infra-manager-processor` | `infra-manager-processor` | The deployment process has failed with an error.
| `provision_successful`    | `infra-manager-processor` | `infra-manager-processor` | The deployment process has succeeded and the sandbox is available and running.
| `delete_requested`        | User Interface            | `firestore-functions`     | The user or lifecycle process has requested that a sandbox be deleted.
| `delete_pending`          | `infra-manager-processor` | `infra-manager-processor` | Indicates the delete request was received by the `infra-manager-processor` but the request hasn’t yet been made to Infrastructure Manager.
| `delete_inprogress`       | `infra-manager-processor` | `infra-manager-processor` | Indicates that the delete request has been submitted to Infrastructure Manager and it is in progress with Infrastructure Manager.
| `delete_error`            | `infra-manager-processor` | `infra-manager-processor` | The delete process has failed with an error.
| `delete_successful`       | `infra-manager-processor` | `infra-manager-processor` | The delete process has succeeded.

<!-- LINKS: https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[inframanager]: https://cloud.google.com/infrastructure-manager
[inframanager-deployment]: https://cloud.google.com/infrastructure-manager/docs/reference/rest/v1/projects.locations.deployments#Deployment
