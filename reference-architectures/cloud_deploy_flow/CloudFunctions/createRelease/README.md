# Example Cloud Function

This project demonstrates a Google Cloud Function that triggers deployments
based on Pub/Sub messages. The function listens for build notifications from
Google Cloud Build and initiates a release in Google Cloud Deploy when a build succeeds.

## Table of Contents

*   [Prerequisites](#prerequisites)
*   [Env](#environment-variables)
*   [Function Overview](#function-overview)
*   [Deploying the Function](#deploying-the-function)

## Prerequisites

*   Go version 1.15 or later
*   Google Cloud account
*   Google Cloud SDK installed and configured
*   Necessary permissions for Cloud Build and Cloud Deploy

## Environment Variables

The function relies on environment variables to specify project configuration.
Ensure these are set before deploying the function:

| Variable Name  | Description                             | Required |
|----------------|-----------------------------------------|----------|
| `PROJECTID`    | Google Cloud project ID                | Yes      |
| `LOCATION`     | The deployment location (region)       | Yes      |
| `PIPELINE`     | The name of the delivery pipeline in Cloud Deploy.| Yes     |
| `TRIGGER`     | The ID of the build trigger in Cloud Build.       | Yes      |
| `SENDTOPICID`  | Pub/Sub topic ID for sending commands  | Yes      |

## Function Overview

The `deployTrigger` function is invoked by Pub/Sub events. Here's a breakdown of
its key components:

1.  **Initialization**:

    *   Loads environment variables into a configuration struct.
    *   Registers the function to be triggered by CloudEvents.

2.  **Message Handling**:

    *   Parses incoming Pub/Sub messages.
    *   Validates build notifications based on specified criteria
    (trigger ID and build status).

3.  **Release Creation**:

    *   Extracts relevant image information from the build notification.
    *   Constructs a `CreateReleaseRequest` for Cloud Deploy.
    *   Sends the request to the specified Pub/Sub topic.

4.  **Random ID Generation**:

    *   Generates a unique release ID to ensure each deployment is distinct.

## Deploying the Function

To deploy the function, follow these steps:

1.  Ensure that your Google Cloud SDK is authenticated and configured with the
      correct project.
2.  Use the following command to deploy the function:

   ```bash
   gcloud functions deploy deployTrigger \
       --runtime go113 \
       --trigger-topic YOUR_TOPIC_NAME \
       --env-file .env
