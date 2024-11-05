
# Cloud Deploy Operations Function

This project contains a Google Cloud Function written in Go, designed to
interact with Google Cloud Deploy. The function listens for deployment events on
a Pub/Sub topic, processes those events, and triggers specific deployment
operations based on the event details. For instance, when a deployment release
succeeds, it triggers a rollout creation and sends the relevant command to
another Pub/Sub topic.

## Requirements

*   Go 1.20 or later
*   Google Cloud SDK
*   Google Cloud Pub/Sub
*   Google Cloud Deploy API
*   Set environment variables for Google Cloud project configuration

## Environment Variables

The function relies on environment variables to specify project configuration.
Ensure these are set before deploying the function:

| Variable Name  | Description                             | Required |
|----------------|-----------------------------------------|----------|
| `PROJECTID`    | Google Cloud project ID                | Yes      |
| `LOCATION`     | The deployment location (region)       | Yes      |
| `SENDTOPICID`  | Pub/Sub topic ID for sending commands  | Yes      |

## Structure

### Main Components

*   **config**: Stores the environment configuration necessary for the function.
*   **PubsubMessage**: Structure representing a message from Pub/Sub, with
`Data` payload and `Attributes` metadata.
*   **OperationsData**: Metadata that describes deployment action and resource details.
*   **CommandMessage**: Structure for deployment commands, like `CreateRollout`.
*   **cloudDeployOperations**: Main Cloud Function triggered by a deployment
event, processes release successes to initiate rollouts.
*   **sendCommandPubSub**: Publishes a `CommandMessage` to a specified Pub/Sub
topic, which triggers deployment operations.

## Function Workflow

1.  **Trigger**: The function `cloudDeployOperations` is triggered by a
deployment event, specifically a CloudEvent.
2.  **Event Parsing**: The function parses the event data into a `Message`
struct, checking for deployment success events.
3.  **Rollout Creation**: If a release success is detected, it creates a
`CommandMessage` for a rollout and calls `sendCommandPubSub`.
4.  **Command Publish**: The `sendCommandPubSub` function publishes the
`CommandMessage` to a designated Pub/Sub topic to initiate the rollout.

## Setup and Deployment

### Local Development

1.  Clone the repository and set up your local environment with the necessary
environment variables.
2.  Run the Cloud Functions framework locally to test the function:

   ```bash
   functions-framework --target=cloudDeployOperations
   ```

### Deployment to Google Cloud Functions

1.  Set up your Google Cloud environment and enable the necessary APIs:

      ```bash
      gcloud services enable cloudfunctions.googleapis.com pubsub.googleapis.com
      clouddeploy.googleapis.com
      ```

2.  Deploy the function to Google Cloud:

      ```bash
      gcloud functions deploy cloudDeployOperations \
         --runtime go120 \
         --trigger-topic <YOUR_TRIGGER_TOPIC> \
         --set-env-vars PROJECTID=<YOUR_PROJECT_ID>,LOCATION=<YOUR_LOCATION>,SENDTOPICID=<YOUR_SEND_TOPIC_ID>
      ```

## Error Handling

*   If message parsing fails, the function logs an error but acknowledges the
message to prevent retries.
*   Command failures are logged, and the function acknowledges the message to
prevent reprocessing of erroneous commands.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

### Notes

*   For production environments, consider validating that the `TargetId` within
 `CommandMessage` is dynamically populated based on actual Pub/Sub message data.
*   The function relies on `pubsub.NewClient` which should be carefully
monitored in production for connection management.
