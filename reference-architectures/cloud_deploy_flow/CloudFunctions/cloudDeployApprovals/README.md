
# Cloud Deployment Approvals with Pub/Sub

This project provides a Google Cloud Run Function to automate deployment approvals
based on messages received via Google Cloud Pub/Sub.
The function processes deployment requests, checks conditions for rollout
approval, and publishes an approval command if the requirements are met.

## Features

*   Listens to Pub/Sub messages for deployment approvals
*   Validates deployment conditions (manual approval, rollout ID, etc.)
*   Publishes approval commands to another Pub/Sub topic if conditions are met

## Setup

### Requirements

*   Go 1.16 or later
*   Google Cloud SDK
*   Access to Google Cloud Pub/Sub
*   Environment variables to configure project details

### Installation

1.  **Clone the repository**:

    ```bash
    git clone <repository-url>
    cd <repository-folder>
    ```

2.  **Enable APIs**:
    Enable the Google Cloud Pub/Sub and Deploy APIs for your project:

    ```bash
    gcloud services enable pubsub.googleapis.com deploy.googleapis.com
    ```

3.  **Deploy the Function**:
    Use Google Cloud SDK to deploy the function:

    ```bash
    gcloud functions deploy cloudDeployApprovals --runtime go116 \
    --trigger-event-type google.cloud.pubsub.topic.v1.messagePublished \
    --trigger-resource YOUR_SUBSCRIBE_TOPIC
    ```

## Environment Variables

The function relies on environment variables to specify project configuration.
Ensure these are set before deploying the function:

| Variable Name  | Description                             | Required |
|----------------|-----------------------------------------|----------|
| `PROJECTID`    | Google Cloud project ID                 | Yes      |
| `LOCATION`     | The deployment location (region)        | Yes      |
| `SENDTOPICID`  | Pub/Sub topic ID for sending commands   | Yes      |

## Code Structure

*   **config struct**: Holds configuration for the environment variables.

*   **PubsubMessage and ApprovalsData structs**: Define the structure of
      messages received from Pub/Sub and attributes within them.

*   **cloudDeployApprovals function**: Entry point for handling messages.
    Validates the conditions and, if met, triggers the `sendCommandPubSub`
    function to send an approval command.

*   **sendCommandPubSub function**: Publishes a command message to the Pub/Sub
    topic to approve a deployment rollout.

## Usage

The function `cloudDeployApprovals` is invoked whenever a message is published
to the configured Pub/Sub topic. Upon receiving a message, the function will:

1.  Parse and validate the message.
2.  Check if the action is `Required`, if a rollout ID is provided, and if
    manual approval is marked as "true."
3.  If conditions are met, it will publish an approval command to the
    `SENDTOPICID` topic.

### Sample Pub/Sub Message

A message sent to the function should resemble this JSON structure:

```json
{
  "message": {
    "data": "<base64-encoded data>",
    "attributes": {
      "Action": "Required",
      "Rollout": "rollout-123",
      "ReleaseId": "release-456",
      "ManualApproval": "true"
    }
  }
}
```

## Custom Manual Approval Field

In the `ApprovalsData` struct, there is a `ManualApproval` field. This field is
a custom addition, not provided by Google Cloud Deploy, and serves as a
placeholder for an external approval system.

To integrate the approval system, you can replace or adapt this field to suit
your existing change process workflow. For instance, you could link this field
to an external ticketing or project management system to track and verify
approvals. Implementing an approval system allows greater control over deployment
rollouts, ensuring they align with your organization’s policies.

## Logging

The function logs each major step, from invocation to message processing and
condition checking, to facilitate debugging and monitoring.
