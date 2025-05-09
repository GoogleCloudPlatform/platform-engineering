# Gemini-powered migration blocker analysis

This document shows how to deploy a reference architecture to use Gemini to
generate templated reports focusing on migration blocker analysis.

To deploy this reference architecture, you need:

- A [Google Cloud project](https://cloud.google.com/docs/overview#projects) with
  billing enabled. We recommend deploying this reference architecture to a new,
  dedicated Google Cloud project.
- An account with either the [Project Owner role](#option-1-project-owner-role)
  (full access) or [Granular Access roles](#option-2-granular-access).
- The `serviceusage.googleapis.com` must be enabled on the project. For more
  information about enabling APIs, see
  [Enabling and disabling services](https://cloud.google.com/service-usage/docs/enable-disable)

## Service account roles and permissions

You can choose between Project Owner access or Granular Access for more
fine-tuned permissions.

### Option 1: Project Owner role

The account you use to deploy this reference architecture has full
administrative access to the project.

- `roles/owner`: Full administrative access to the project
  ([Project Owner role](https://cloud.google.com/iam/docs/understanding-roles#resource-manager-roles))

### Option 2: Granular access

The account you use to deploy this reference architecture has only the
permissions granted by the following roles:

- TODO

## Understand the repository structure

The `reference-architectures/gemini-powered-migration-blocker-analysis`
reference architecture has the following directories and files:

- `terraform`: contains Terraform descriptors and configuration to deploy the
  reference architecture.
- `compose.yaml`: Docker Compose descriptor for local deployment.
- `deploy.sh`: convenience script to deploy the reference architecture.
- `teardown.sh`: convenience script to destroy the reference architecture.
- `common.sh`: contains common shell variables and functions.
- `backend`: contains the implementation of the reference architecture backend.
- `frontend`: contains the implementation of the reference architecture
  frontend.
- `sample-platform`: contains static assets that describe a hypotethical
  internal development platform.
- `README.md`: this document.

## Architecture

TODO

## Deploy and run the application

The reference architecture supports two deployment environments:

- [Google Cloud deployment](#deploy-on-google-cloud).
- [Local deployment using Docker Compose](#run-locally-with-docker-compose),
  useful for development workflows.

Regardless of the deployment environment, this reference architecture needs
[Google Cloud resources](#provision-google-cloud-resources) to store data, and
to interact with Gemini.

### Provision Google Cloud resources

1. Open your shell.

2. Clone this repository.

3. Change the working directory to the directory where you cloned this
   repository.

4. Change the working directory to
   `reference-architectures/gemini-powered-migration-blocker-analysis`:

    ```bash
    cd reference-architectures/gemini-powered-migration-blocker-analysis
    ```

5. Run the deployment script:

    ```bash
    TF_VAR_default_project_id="<default_project_id>" \
    TF_VAR_terraform_project_id="<terraform_project_id>" \
    TF_VAR_terraform_backend_bucket_location="<terraform_bucket_location>" \
    ./deploy.sh
    ```

    Where:

    - `<default_project_id>` is the id of the project where to create resources
      to deploy this reference architecture.
    - `<terraform_project_id>` is the id of the project where to create
      resources to run Terraform.
    - `<terraform_bucket_location>` is the location where to create the Cloud
      Storage bucket to configure the Terraform backend.

    After running the deployment script to completion, Terraform persists these
    configuration variables in the `_shared_config` directory, so you don't need
    to set them on future invocations of the deployment script.

### Deploy on Google Cloud

TODO

### Run locally with Docker Compose

Pre-requisites:

- A Linux shell. Tested with Bash version `5.2.37`
- Docker. Tested with version `28.0.4`
- Docker Compose. Tested with version `v2.34.0`

To run this application using Docker Compose, you do the following:

1. Open your shell.

2. Change the working directory to the directory where you cloned this
   repository.

3. Change the working directory to
   `reference-architectures/gemini-powered-migration-blocker-analysis`:

    ```bash
    cd reference-architectures/gemini-powered-migration-blocker-analysis
    ```

4. Run the application using Docker Compose

    ```bash
    UID="$(id -u)" GID="$(id -g)" docker compose up --build --renew-anon-volumes
    ```

## Configure the Federated learning reference architecture

You can configure the reference architecture by modifying files in the following
directories:

- `reference-architectures/gemini-powered-migration-blocker-analysis/terraform/_shared_config`

## Destroy the reference architecture

To destroy an instance of the reference architecture, you do the following:

1. Open your shell.

2. Change the working directory to the directory where you cloned this
   repository.

3. Run the script to destroy the reference architecture:

    ```sh
    "reference-architectures/gemini-powered-migration-blocker-analysis/teardown.sh"
    ```

## Troubleshooting

This section describes common issues and troubleshooting steps.
