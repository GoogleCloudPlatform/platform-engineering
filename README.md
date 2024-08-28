# Platform Engineering on Google Cloud

Platform engineering is an emerging practice in organizations to enable cross
functional collaboration in order to deliver business value faster. It treats
the internal groups; application developers, operators, security,
infrastructure admins, etc. as customers and provides them the foundational
platforms to accelerate their work. The key goals of platform engineering are
providing everything as self-service, golden paths, improved collaboration,
abstraction of technical complexities, all of which simplify the software
development lifecycle, contributing towards delivering business values to
consumers. Platform engineering is more effective in cloud computing as it
helps realize the benefits possible on cloud like automation, security,
productivity, faster time-to-market.

## Overview

Google Cloud offers decomposable, elastic, secure, scalable and cost efficient
tools built on the guiding principles of platform engineering. With a focus on
developer experience and innovation coupled with practices like SRE embedded
into the tools, they make a good place to begin your platform journey to
empower the developers to enhance their experience and increase their
productivity.

This repo contains a collection of guides, examples and design patterns
spanning Google Cloud products and best in class OSS tools, which you can use
to help build an internal developer platform.

## Resources

### Guides and Building Blocks

#### Manage Developer Environments at Scale

*   [Backstage Plugin for Cloud Workstations][backstage-cloudworkstations]

### End-to-end Examples

*   [Enterprise Application Blueprint][enterprise-app-blueprint] - Deploys an
    internal developer platform that enables cloud platform teams to provide a
    managed software development and delivery platform for their organization's
    application development groups. EAB builds upon the infrastructure
    foundation deployed using the
    [Enterprise Foundation blueprint][enterprise-foundation-blueprint].
*   [Software Delivery Blueprint][software-delivery-blueprint] - An opinionated
    approach using platform engineering to improve software delivery,
    specifically for Infrastructure admins, Operators, Security specialists, and
    Application developers. It utilizes GitOps and self-service workflows to
    enable consistent infrastructure, automated security policies, and
    autonomous application deployment for developers.

## Usage Disclaimer

**Copy any code you need from this repository into your own project.**

Warning: Do not depend directly on the samples in this repo. Breaking changes
may be made at any time without warning.

## Contributing changes

Entirely new samples are not accepted. Bug fixes are welcome, either as pull
requests or as GitHub issues.

See [CONTRIBUTING.md](docs/contributing.md) for details on how to contribute.

## Licensing

Copyright 2024 Google LLC
Code in this repository is licensed under the Apache 2.0. See [LICENSE](LICENSE).

<!-- LINKS: https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[backstage-cloudworkstations]: https://github.com/googlecloudplatform/google-cloud-backstage-plugins
[enterprise-app-blueprint]: https://github.com/GoogleCloudPlatform/terraform-google-enterprise-application
[enterprise-foundation-blueprint]: https://github.com/terraform-google-modules/terraform-example-foundation/tree/master
[software-delivery-blueprint]: https://github.com/GoogleCloudPlatform/software-delivery-blueprint
