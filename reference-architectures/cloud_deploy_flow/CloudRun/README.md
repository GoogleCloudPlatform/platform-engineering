# Random Date Service

This repository contains a sample application designed to demonstrate how
deployments can work through Google Cloud Deploy and Cloud Build. Instead of a
traditional "Hello World" application, this project generates and serves a
random date, showcasing how to set up a cloud-based service.

## Usage Note

This code is designed to integrate with the Terraform configuration for the
[cloud_deploy_flow](../README.md) demo. While you can deploy this component
individually, it's primarily intended to be used as part of the full
Terraform-managed workflow. Please note that this section of the readme may be
less actively maintained, as the preferred deployment method relies on the
Terraform setup.

## Overview

The `Random Date Service` is built to illustrate the process of deploying an
application using Cloud Run and Cloud Deploy. The application serves a random
date formatted as a string. This simple service allows you to explore key
concepts in cloud deployment without the complexity of a full-fledged
application.

## Components

### 1. **main.go**

This is the core of the application, where the HTTP server is defined. It
handles requests and responds with a randomly generated date.

### 2. **Dockerfile**

The Dockerfile specifies how to build a container image for the application.
This image will be used in Cloud Run for deploying the service.

### 3. **skaffold.yaml**

This file is configured for Google Cloud Deploy, facilitating the deployment
process by managing builds and configurations in a single file.

### 4. **run.yaml**

The `run.yaml` file defines the configuration for Cloud Run and Cloud Deploy.
Key aspects to note include:

- **Service Name**: This defines the name of the service as
  `random-date-service`.
- **Image Specification**: The `image` field under `spec` is set to `pizza`.
  This is crucial, as it indicates to Cloud Deploy where to substitute the
  image. This substitution occurs based on the `createRelease` function in
  `main.go`, specifically noted on line 122.

## Usage

To deploy and test this application:

1.  **Build the Docker Image**: Use the provided Dockerfile to create a
    container image.
2.  **Deploy to Cloud Run**: Utilize the `run.yaml` configuration to deploy the
    service.
3.  **Monitor Deployments**: Use Cloud Deploy to observe the deployment pipeline
    and ensure the service is running as expected.
4.  **Access the Service**: After deployment, access the service through its
    endpoint to receive a random date.

## Conclusion

This sample application serves as a foundational example of how to leverage
cloud services for deploying applications. By utilizing Google Cloud Deploy and
Cloud Build, you can understand the deployment lifecycle and how cloud-native
applications can be effectively managed and served.

Feel free to explore the code and configurations provided in this repository to
get a better grasp of the deployment process.
