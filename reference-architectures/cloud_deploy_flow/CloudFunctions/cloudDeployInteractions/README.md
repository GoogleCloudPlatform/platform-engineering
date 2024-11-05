
# Cloud Deploy Interactions with Pub/Sub

This project demonstrates a Google Cloud Function to manage deployments by creating releases, rollouts, or approving rollouts based on incoming Pub/Sub messages. The function leverages Google Cloud Deploy and listens for deployment-related commands sent via Pub/Sub, executing appropriate actions based on the command type.

## Features

- Listens for Pub/Sub messages with deployment commands (CreateRelease, CreateRollout, ApproveRollout) Messages should include protobuf request.
- Initiates Google Cloud Deploy actions based on the received command.
- Logs each step of the deployment process for better traceability.

## Setup

### Requirements

- Go 1.16 or later
- Google Cloud SDK
- Access to Google Cloud Deploy and Pub/Sub

### Installation

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd <repository-folder>
   ```

2. **Set up Google Cloud**:
   Ensure you have enabled the Google Cloud Deploy and Pub/Sub APIs in your project.

3. **Deploy the Function**:
   Deploy the function using Google Cloud SDK:

   ```bash
   gcloud functions deploy cloudDeployInteractions --runtime go116 --trigger-event-type google.cloud.pubsub.topic.v1.messagePublished --trigger-resource YOUR_TOPIC_NAME
   ```

### Pub/Sub Message Format

The Pub/Sub message should include a JSON payload with a `command` field specifying the type of deployment action to execute. Examples of the command types include:

- `CreateRelease`: Creates a new release for deployment.
- `CreateRollout`: Initiates a rollout of the release.
- `ApproveRollout`: Approves a pending rollout.

### Sample Pub/Sub Message

The message should follow this structure:

```json
{
  "message": {
    "data": "<base64-encoded JSON containing command data>"
  }
}
```

The JSON inside `data` should follow the format for `DeployCommand`:

```json
{
  "command": "CreateRelease",
  "createReleaseRequest": {
    // Release creation parameters
  },
  "createRolloutRequest": {
    // Rollout creation parameters
  },
  "approveRolloutRequest": {
    // Rollout approval parameters
  }
}
```

## Code Structure

- **DeployCommand struct**: Defines the command to be executed and the parameters for each deploy action (create release, create rollout, or approve rollout).
- **cloudDeployInteractions function**: Main function triggered by Pub/Sub messages. It parses the message and calls the respective deployment function based on the command.
- **cdCreateRelease**: Creates a release in Google Cloud Deploy.
- **cdCreateRollout**: Initiates a rollout for a specified release.
- **cdApproveRollout**: Approves an existing rollout.

## Logging

Each function logs key steps, from initialization to message handling and completion of deployments, helping in troubleshooting and monitoring.
