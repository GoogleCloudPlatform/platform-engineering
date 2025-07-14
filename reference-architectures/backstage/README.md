# Backstage on Google Cloud

[Backstage][backstage] is an open-source framework for building developer portals.  Originally developed by Spotify in 2016 and used extensively by their internal teams, it is now OSS and part of the [CNCF][cncf] since September of 2020, as of March 2022 it has been categorized as an incubation level project.  It is developed in TypeScript with a React frontend and Node.js backend system.

This portion of the repository contains a collection of resources related to utilizing [Backstage][backstage] on Google
Cloud. The resources are organized such that you can quickly get started, then add layers of operational capailities to your deployment and finally end-user workflows, plugins and uses cases built on Backstge.

## Backstage Quickstart

This is an [example deployment][quickstart] of Backstage on Google Cloud with
various Google Cloud services providing the infrastructure.

## Operationalizing Backstage

This example show how to build a Continuous Integration and Deployment (CI/CD) pipeline for your backstage deployment.

## Backstage Plugins for Google Cloud

A repository for various plugins can be found here ->
[google-cloud-backstage-plugins][backstage-cloudworkstations]

<!-- LINKS: https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[backstage]: https://backstage.io
[backstage-cloudworkstations]:
    https://github.com/googlecloudplatform/google-cloud-backstage-plugins
[cncf]: https://www.cncf.io/projects/backstage/
[quickstart]: ./backstage-quickstart/README.md
