# Reference Guide: Deploy and use GitHub Actions Runners on GKE

## Overview

This guide walks you through the process of setting up self-hosted GitHub
Actions Runners on Google Kubernetes Engine (GKE) using the Terraform module
[`terraform-google-github-actions-runners`](https://github.com/terraform-google-modules/terraform-google-github-actions-runners).
It then provides instructions on how to create a basic GitHub Actions workflow
to leverage these runners.

## Prerequisites

*   **Terraform:** Install Terraform on your local machine or use Cloud Shell  
*   **Google Cloud Project:** Have a Google Cloud project with a Billing Account
    linked and the following APIs enabled:  
    *   Cloud Resource Manager API `cloudresourcemanager.googleapis.com`  
    *   Identity and Access Management API `iam.googleapis.com`  
    *   Kubernetes Engine API `container.googleapis.com`  
    *   Service Usage API `serviceusage.googleapis.com`  
*   **GitHub Account:** Have a GitHub organization, either personal or
    enterprise, where you have administrator access.

## Register a GitHub App for Authenticating ARC

Using a GitHub App for authentication allows you to make your self-hosted
runners available to a GitHub organization that you own or have administrative
access to. For more details on registering GitHub Apps, see [GitHub’s documentation](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app).

You will need 3 values from this section to use as inputs in the Terraform module:

*   GitHub App ID  
*   GitHub App Private Key  
*   GitHub App Installation ID

### Navigate to your Organization GitHub App settings

1.  Click your profile picture in the top-right  
2.  Click **Your organizations**  
3.  Select the organization you want to use for this walkthrough  
4.  Click **Settings**  
5.  Click \<\> **Developer settings**  
6.  Click **GitHub Apps**

### Create a new GitHub App

1.  Click **New GitHub App**
2.  Under “GitHub App name”, choose a unique name such as “my-gke-arc-app”
3.  Under “Homepage URL” enter `https://github.com/actions/actions-runner-controller`
4.  Under “Webhook,” uncheck **Active**.  
5.  Under “Permissions,” click **Repository permissions** and use the dropdown
    menu to select the following permissions:
    1.  **Metadata**: Read-only
6.  Under “Permissions,” click **Organization permissions** and use the dropdown
    menu to select the following permissions:
    1.  **Self-hosted runners**: Read and write
7.  Click the **Create GitHub App** button

### Gather required IDs and keys

1.  On the GitHub App’s page, save the value for “App ID”
    1.  You will use this as the value for `gh_app_id` in the Terraform module
2.  Under “Private keys” click **Generate a private key**. Save the `.pem` file
    for later.
    1.  You will use this as the value for `gh_app_private_key` in the Terraform
        module
3.  In the menu at the top-left corner of the page, click **Install App**, and
    next to your organization, click **Install** to install the app on your organization.
    1.  Choose **All repositories** to allow any repo in your org to have access
        to your runners
    2.  Choose **Only select repositories** to allow specific repos to have
        access to your runners
4.  Note the app installation ID, which you can find on the app installation
    page, which has the following URL format: [`https://github.com/organizations/ORGANIZATION/settings/installations/INSTALLATION_ID`](https://github.com/organizations/ORGANIZATION/settings/installations/INSTALLATION_ID)
    1.  You will use this as the value for `gh_app_installation_id` in the
        Terraform module.

## Configure Terraform example

### Open the Terraform example

Open the Terraform module repo in Cloud Shell automatically by clicking the button:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fterraform-google-modules%2Fterraform-google-github-actions-runners&cloudshell_git_branch=master&cloudshell_open_in_editor=examples%2Fgh-runner-gke-simple%2Fmain.tf&cloudshell_workspace=examples%2Fgh-runner-gke-simple)

Clicking this button will clone the repo into Cloud Shell, change into the
example directory, and open the `main.tf` file in the Cloud Shell Editor.

### Modify Terraform example variables

1.  Insert your Google Cloud Project ID as the value of `project_id`
2.  Modify the sample values of the following variables with the values you
    saved from earlier.
    1.  `gh_app_id`: insert the value of the App ID from the GitHub App page
    2.  `gh_app_installation_id`: insert the value from the URL of the app
        installation page
    3.  `gh_app_private_key`:
        1.  Copy the `.pem` file to example directory, alongside the `main.tf` file
        2.  Insert the `.pem` file name you downloaded after generating the
            private key for the app, like so:
            1.  `gh_app_private_key = file("example.private-key.pem")`
        3.  Warning: Terraform will store the private key in state as plaintext.
            It’s recommended to secure your state file by using a backend such
            as a GCS bucket with encryption. You can do so by following [these instructions](https://cloud.google.com/docs/terraform/best-practices/security).
3.  Modify the value of `gh_config_url` with the URL of your GitHub
    organization. It will be in the format of `https://github.com/ORGANIZATION`
4.  (Optional) Specify any other parameters that you wish. For a full list of
    variables you can modify, refer to the [module documentation](https://github.com/terraform-google-modules/terraform-google-github-actions-runners/tree/master/modules/gh-runner-gke#inputs).

### Deploy the example

1.  **Initialize Terraform:** Run `terraform init` to download the required providers.
2.  **Plan:** Run `terraform plan` to preview the changes that will be made.
3.  **Apply:** Run `terraform apply` and confirm to create the resources.

You will see the runners become available in your GitHub Organization:

1.  Go to your GitHub organization page
2.  Click **Settings**
3.  Open the “Actions” drop-down in the left menu and choose **Runners**

You should see the runners appear as “arc-runners”

## Creating a GitHub Actions Workflow

1.  Create a new GitHub repository within your organization.  
2.  In your GitHub repository, click the **Actions** tab.  
3.  Click **New workflow**  
4.  Under “Choose workflow” click **set up a workflow yourself**
5.  Paste the following configuration into the text editor:

    ```yaml
    name: Actions Runner Controller Demo
    on:
    workflow_dispatch:
    jobs:
    Explore-GitHub-Actions:
       runs-on: arc-runners
       steps:
       - run: echo "This job uses runner scale set runners!"
    ```

6.  Click **Commit changes** to save the workflow to your repo.

### Test the GitHub Actions Workflow

1.  Go back to the **Actions** tab in your repo.  
2.  In the left menu, select the name of your workflow. This should be “Actions
    Runner Controller Demo” if you left the above configuration unchanged
3.  Click **Run workflow** to open the drop-down menu, and click
    **Run workflow**  
4.  The sample workflow executes on your GKE-hosted ARC runner set. You can view
    the output within the GitHub Actions run history.

## Cleanup

### Teardown Terraform-managed infrastructure

1.  Navigate back into the example directory you previously ran `terraform apply`

    ```bash
    cd terraform-google-github-actions-runners/examples/gh-runner-gke-simple/
    ```

2.  Destroy Terraform-managed infrastructure

    ```bash
    terraform destroy
    ```

Warning: this will destroy the GKE cluster, example VPC, service accounts, and
the Helm-managed workloads previously deployed by this example.

### Delete GitHub resources

If you created a new GitHub App for testing purposes of this walkthrough, you
can delete it via the following instructions. Note that any services
authenticating via this GitHub App will lose access.

1.  Navigate to your Organization GitHub App settings  
    1.  Click your profile picture in the top-right  
    2.  Click **Your organizations**  
    3.  Select the organization you used for this walkthrough  
    4.  Click **Settings**  
    5.  Click the \<\> **Developer settings** drop-down  
    6.  Click **GitHub Apps**  
2.  In the row where your GitHub App is listed, click **Edit**  
3.  In the left-side menu, click **Advanced**  
4.  Click **Delete GitHub App**  
5.  Type the name of the GitHub App to confirm and delete.
