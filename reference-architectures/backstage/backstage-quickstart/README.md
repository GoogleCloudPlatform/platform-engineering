# Backstage on Google Cloud Quickstart

This quick-start deployment guide can be used to set up an environment to familiarize yourself with the architecture and get an understanding of the concepts related to hosting Backstage on Google Cloud.

**NOTE: This environment is not intended to be a long lived environment. It is intended for temporary demonstration and learning purposes.  You will need to modify the configurations provided to align with your orginazations needs.**

## Architecture

For more information about the architecture, see the [Backstage on Google Cloud: Architecture](docs/backstage-quickstart-architecture.md) document.

## Requirements

### Project

In this guide you can choose to bring your project (BYOP) or have Terraform create a new project for you. The requirements are different based on the option that you choose.

#### Option 1: Bring your own project (BYOP)

- Project ID of a Google Cloud Project
- `roles/owner` IAM permissions on the project
- GitHub Personal Access Token, steps to create the token are provided below

#### Option 2: Terraform managed project

- Billing account ID
- Organization or folder ID
- `roles/billing.user` IAM permissions on the billing account specified
- `roles/resourcemanager.projectCreator` IAM permissions on the organization or folder specified
- GitHub Personal Access Token, steps to create the token are provided below

## Pull the source code

**NOTE: This tutorial is designed to be run from Cloud Shell in the Google Cloud Console.**

- Clone the repository and change directory to the guide directory

  ```bash
  git clone https://github.com/GoogleCloudPlatform/platform-engineering && \
  cd platform-engineering/reference-architectures/backstage/backstage-quickstart

  ```

- Set environment variables

  ```bash
  export BACKSTAGE_QS_BASE_DIR=$(pwd) && \
  sed -n -i -e '/^export BACKSTAGE_QS_BASE_DIR=/!p' -i -e '$aexport BACKSTAGE_QS_BASE_DIR="'"${BACKSTAGE_QS_BASE_DIR}"'"' ${HOME}/.bashrc
  ```

## Project Configuration

You only need to complete the section for the option that you have selected (either option 1 or 2).

### Option 1: Bring your own project config (BYOP)

- Set the project environment variables in Cloud Shell

  Replace the following values

  - `<PROJECT_ID>` is the ID of your existing Google Cloud project

  ```bash
  export BACKSTAGE_QS_PROJECT_ID="<PROJECT_ID>"
  export BACKSTAGE_QS_STATE_BUCKET="${BACKSTAGE_QS_PROJECT_ID}-terraform"
  ```

- Set the default `gcloud` project

  ```bash
  gcloud config set project ${BACKSTAGE_QS_PROJECT_ID}
  ```

- Authorize `gcloud`

  ```bash
  gcloud auth login --activate --no-launch-browser --quiet --update-adc
  ```

- Create a Cloud Storage bucket to store the Terraform state

  ```bash
  gcloud storage buckets create gs://${BACKSTAGE_QS_STATE_BUCKET} --project ${BACKSTAGE_QS_PROJECT_ID}
  ```

- Set the configuration variables

  ```bash
  sed -i "s/YOUR_STATE_BUCKET/${BACKSTAGE_QS_STATE_BUCKET}/g" ${BACKSTAGE_QS_BASE_DIR}/backend.tf
  sed -i "s/YOUR_PROJECT_ID/${BACKSTAGE_QS_PROJECT_ID}/g" ${BACKSTAGE_QS_BASE_DIR}/backstage-qs.auto.tfvars
  ```

You can now the [Create the resources](#create-the-resources).

### Option 2: Terraform managed project config

- Set the configuration variables

  ```bash
  nano ${BACKSTAGE_QS_BASE_DIR}/initialize/initialize.auto.tfvars
  ```

  ```bash
  environment_name  = "qs"
  iapUserDomain = ""
  iapSupportEmail = ""
  project = {
    billing_account_id = "XXXXXX-XXXXXX-XXXXXX"
    folder_id          = "############"
    name               = "backstage"
    org_id             = "############"
  }
  ```

  - `environment_name`: the name of the environment (defaults to qs for quickstart)
  - `iapUserDomain`: the root domain of the GCP Org that the Backstage users will be in
  - `iapSupportEmail`: support contact for the IAP brand
  - `project.billing_account_id`: the billing account ID
  - `project.name`: the prefix for the display name of the project, the full name will be `<project.name>-<environment_name>`

  Enter either `project.folder_id` **OR** `project.org_id`

  - `project.folder_id`: the Google Cloud folder ID
  - `project.org_id`: the Google Cloud organization ID

- Authorize `gcloud`

  ```bash
  gcloud auth login --activate --no-launch-browser --quiet --update-adc
  ```

- Create a new project

  ```bash
  cd ${BACKSTAGE_QS_BASE_DIR}/initialize
  terraform init && \
  terraform plan -input=false -out=tfplan && \
  terraform apply -input=false tfplan && \
  rm tfplan && \
  terraform init -force-copy -migrate-state && \
  rm -rf state
  ```

- Set the project environment variables in Cloud Shell

  ```bash
  BACKSTAGE_QS_PROJECT_ID=$(grep environment_project_id ${BACKSTAGE_QS_BASE_DIR}/backstage-qs.auto.tfvars | awk -F"=" '{print $2}' | xargs)
  ```

You can now the [Create the resources](#create-the-resources).

## Create the resources

- In situations where you have run this quickstart before and then cleaned-up the resources but are re-using the project, it might be neccasary to restore the endpoints from a deleted state first.

  ```bash
  BACKSTAGE_QS_PREFIX=$(grep environment_name ${BACKSTAGE_QS_BASE_DIR}/backstage-qs.auto.tfvars | awk -F"=" '{print $2}' | xargs)
  BACKSTAGE_QS_PROJECT_ID=$(grep environment_project_id ${BACKSTAGE_QS_BASE_DIR}/backstage-qs.auto.tfvars | awk -F"=" '{print $2}' | xargs)
  gcloud endpoints services undelete ${BACKSTAGE_QS_PREFIX}.endpoints.${BACKSTAGE_QS_PROJECT_ID}.cloud.goog --quiet 2>/dev/null
  ```

- Create the resources

  ```bash
  cd ${BACKSTAGE_QS_BASE_DIR} && \
  terraform init && \
  terraform plan -input=false -out=tfplan && \
  terraform apply -input=false tfplan && \
  rm tfplan
  ```

  This will take a while to create all of the required resources, figure somewhere between 15 and 20 minutes.

## Cleanup

### Resources

- Destroy the resources

  ```bash
  cd ${BACKSTAGE_QS_BASE_DIR} && \
  terraform init && \
  terraform destroy -auto-approve && \
  rm -rf .terraform .terraform.lock.hcl
  ```

### Project Deletion

You only need to complete the section for the option that you have selected.

#### Option 1: Bring your own project deletion (BYOP)

- Delete the project

  ```bash
  gcloud projects delete ${BACKSTAGE_QS_PROJECT_ID}
  ```

#### Option 2: Terraform managed project deletion

- Destroy the project

  ```bash
  cd ${BACKSTAGE_QS_BASE_DIR}/initialize && \
  TERRAFORM_BUCKET_NAME=$(grep bucket backend.tf | awk -F"=" '{print $2}' | xargs) && \
  cp backend.tf.local backend.tf && \
  terraform init -force-copy -lock=false -migrate-state && \
  gsutil -m rm -rf gs://${TERRAFORM_BUCKET_NAME}/* && \
  terraform init && \
  terraform destroy -auto-approve  && \
  rm -rf .terraform .terraform.lock.hcl state/
  ```

  ### Environment configuration

- Remove Terraform files and temporary files

  ```bash
  cd ${BACKSTAGE_QS_BASE_DIR} && \
  rm -rf \
  .terraform \
  .terraform.lock.hcl \
  initialize/.terraform \
  initialize/.terraform.lock.hcl \
  initialize/backend.tf.local \
  initialize/state
  ```

- Reset the TF variables file

  ```bash
  cd ${BACKSTAGE_QS_BASE_DIR} && \
  cp backstage-qs-auto.tfvars.local backstage-qs.auto.tfvars

- Remove the environment variables

  ```bash
  sed \
  -i -e '/^export BACKSTAGE_QS_BASE_DIR=/d' \
  ${HOME}/.bashrc
  ```
