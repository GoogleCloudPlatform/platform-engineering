# Overview

This directory contains Terraform configuration files that let you deploy the
system project. This example is a good entry point for testing the reference
architecture and learning how it can be incorportated into your own
infrastructure as code processes.

## Architecture

![architecture-per-project](../../resources/high-level-arch.png)

For an explanation of the components of the sandboxes reference architecture and
the interaction flow, read the
[main Architecture section](../README.md#architecture).

## Before you begin

In this section you prepare a folder for deployment.

1.  Open the [Cloud Console][cloud-console]
2.  Activate [Cloud Shell][cloud-shell] \
    At the bottom of the Cloud Console, a [Cloud Shell][cloud-shell-features]
    session starts and displays a command-line prompt.

3.  In Cloud Shell, clone this repository

    ```sh
    git clone https://github.com/GoogleCloudPlatform/platform-engineering.git
    ```

4.  Export variables for the working directories

    ```sh
    export SANDBOXES_DIR="$(pwd)/reference-architectures/examples/gcp-sandboxes"
    export SANDBOXES_CLI="$(pwd)/reference-architectures/examples/cli"
    ```

### Preparing the Sandboxes Folder

In this section you prepare your environment for deploying the system project.

1.  Go to the [Manage Resources][manage-resources] page in the Cloud Console in
    the IAM & Admin menu.

2.  Click _Create folder_, then choose Folder.

3.  Enter a name for your folder. This folder will be used to contain the system
    and sandbox projects.

4.  Click _Create_

5.  Copy the folder ID from the Manage resources page, you will need this value
    later for use as Terraform variable.

### Deploying the reference architecture

1.  Set the project ID and region in the corresponding Terraform environment
    variables

    ```sh
    export TF_VAR_billing_account="<your billing account id>"
    export TF_VAR_sandboxes_folder="folders/<folder id from step 5>"
    export TF_VAR_system_project_name="<name for the system project>"
    ```

2.  Change directory into the Terraform example directory and initialize
    Terraform.

    ```sh
    cd "${SANDBOXES_DIR}"
    terraform init
    ```

3.  Apply the configuration. Answer `yes` when prompted, after reviewing the
    resources that Terraform intends to create.

    ```sh
    terraform apply
    ```

### Creating a sandbox

Now that the system project has been deployed, create a sandbox using the
example cli.

1.  Change directory into the example command-line tool directory

    ```sh
    cd "${SANDBOXES_DIR}"
    ```

2.  Install there required Python libraries

    ```sh
    pip install -r requirements.txt
    ```

3.  Create a Sandbox using the cli

    ```sh
    python ./sandbox.py create \
    --system="<name of your system project>" \
    --project_id="<name of the sandbox to create>"
    ```

## Next steps

Your sandboxes infrastructure is ready, you may continue to use the example cli
to create and delete sandboxes. At this point it is recommended that you:

- Review the [detailed object and operating model][object-model]
- Adapt the CLI to meet your organization's requirements

<!-- LINKS: https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[cloud-console]: https://console.cloud.google.com
[cloud-shell]: https://console.cloud.google.com/?cloudshell=true
[cloud-shell-features]: https://cloud.google.com/shell/docs/features
[object-model]: ../../sandbox-modules/README.md
[manage-resources]: https://console.cloud.google.com/cloud-resource-manage
