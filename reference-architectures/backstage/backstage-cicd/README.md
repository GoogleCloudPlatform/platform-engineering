# CI/CD for Backstage on Google Cloud

This deployment guide can be used to set up a CI/CD pipeline for [Backstage][backstage] running on Google Cloud. This guide builds on the [quickstart][quickstart] and assumes the GKE cluster, Cloud SQL database are all setup and running. The goal of this guide is to demonstrate how to go beyond a single deployment but long-lived deployment that you can build on as a part of your internal developer platform. If you have not already done so we encourage you to review and run through the [quickstart][quickstart] if you have not already done so.

## Architecture

The following diagram depicts the high level architecture of the infrastucture
that will be deployed. The tools in the architecture used to run the Backstage instance are largely the same. In this guide you will be adding tools to improve how your Backstage instance is built and deployed, highlighted in red.

![architecture](resources/arch.png)

## Requirements and Assumptions

To keep this guide simple it makes a few assumptions. Where the are alternatives
we have linked to some additional documentation.

1.  You have worked through Backstage quick start, meaning you have an existing project with Backstage up and running.
2.  You have a private repository that you will use to store the Backstage code, Terraform and configuration. In this guide we'll be using GitHub as the example, see for GitHub see [Creating a new repository][github] for instructions on creating a new repo.
3.  Your git repository is setup for SSH authentication

## Before you begin

In this section you prepare a folder for deployment.

1.  Open the [Cloud Console][cloud-console]
2.  Activate [Cloud Shell][cloud-shell] \
    At the bottom of the Cloud Console, a [Cloud Shell][cloud-shell-features]
    session starts and displays a command-line prompt.

## Initializing your repository

1.  Clone your Git repository

    ```bash
    export GITHUB_ORG=<YOUR_GITHUB_ORG>
    export GITHUB_REPO=<YOUR_REPO>
    cd ~
    git clone git@github.com:${GITHUB_ORG}/${GITHUB_REPO}.git
    cd ${GITHUB_REPO}
    ```

2.  Install the Backstage codebase.

    ```bash
    export BACKSTAGE_APP_NAME="backstage-qs"
    printf "${BACKSTAGE_APP_NAME}\n" | npx @backstage/create-app@latest --skip-install
    ```

3.  Install Backstage and the the plugins

    ```bash
    cd backstage-qs

    # yarn install
    yarn --cwd packages/backend add pg
    yarn --cwd packages/backend add @backstage/plugin-auth-backend-module-gcp-iap-provider

    cp ${BACKSTAGE_QS_BASE_DIR}/manifests/cloudbuild/index.ts packages/backend/src/index.ts
    cp ${BACKSTAGE_QS_BASE_DIR}/manifests/cloudbuild/App.tsx packages/app/src/App.tsx
    
    cd ~/${GITHUB_REPO}
    ```

4.  Copy across the Terraform

    ```bash
    mkdir terraform
    cp ${BACKSTAGE_QS_BASE_DIR}/*.tf terraform/
    cp ${BACKSTAGE_QS_BASE_DIR}/*.tfvars terraform/
    mkdir terraform/manifests
    cp ${BACKSTAGE_QS_BASE_DIR}/manifests/templates terraform/manifests/templates
    ```




<!-- LINKS: https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[backstage]: https://backstage.io/
[github]: https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository
[quickstart]: ../backstage-quickstart/README.md