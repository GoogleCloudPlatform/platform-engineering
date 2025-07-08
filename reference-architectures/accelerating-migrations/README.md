# Accelerate migrations through platform engineering golden paths

This document helps you adopt
[platform engineering](https://cloud.google.com/blog/products/application-development/golden-paths-for-engineering-execution-consistency)
by designing a process to onboard and migrate your existing applications to use
your internal developer platform (IDP). It also provides guidance to help you
evaluate the opportunity to design a platform engineering process, and to
explore how it might function. Google Cloud provides tools, products, guidance,
and professional services to help you adopt platform engineering in your
environments.

This document is aimed at the following personas:

- **Application developers**, to help them understand how to refactor and
  modernize applications to onboard and migrate them on the IDP.
- **Application operator**, to help them understand how to integrate the
  application with the IDP's observability mechanisms.
- **Platform administrators**, to highlight possible platform enhancements to
  ease onboarding and migration of applications.
- **Database administrators**, to help them migrate from self-managed databases
  to managed database services.
- **Security specialists**, to outline possible security challenges and benefit
  from IDP's security solutions.

The
[Cloud Native Computing Foundation](https://tag-app-delivery.cncf.io/whitepapers/platforms/)
defines a _golden path_ as an integrated bundle of templates and documentation
for rapid project development. Designing and developing golden paths can help
facilitate the onboarding and the migration of existing applications to your
IDP. When you use a golden path, your development and operations teams can take
advantage of benefits like the following:

- Streamlined, self-service development and deployment processes.
- Ready-to-use infrastructure, and templates for your projects.
- Observability instrumentation.
- Extensive reference documentation.

Onboarding and migrating existing applications to the IDP can let you experience
the benefits of adopting platform engineering gradually and incrementally in
your organization, without spending effort on large scale migration projects.

To migrate applications and onboard them to the IDP, we recommend that you
design an _application onboarding and migration process_. This document
describes a reference application onboarding and migration process. We recommend
that you tailor the process to your requirements and your IDP.

If you're migrating your applications from your on-premises environment or from
another cloud provider to Google Cloud, the application onboarding and migration
process can help you to accelerate your migration. In that scenario, the teams
that are managing the migration can refer to well-established golden paths,
instead of having to design their own migration processes and project templates.

## Application onboarding and migration process

The goal of the application onboarding and migration process is to get an
application on the IDP. After you onboard and migrate the application to the
IDP, your teams can benefit from using the IDP. When you use an IDP, you can
focus on providing business value for the application, rather than spending
effort on ad-hoc processes and operations.

To manage the complexity of the application onboarding and migration process, we
recommend that you design the process in the following phases:

1. Intake the application onboarding and migration request.
2. Assess the application to onboard and migrate.
3. Set up and eventually extend the IDP to accommodate the needs of the
   application to onboard and migrate.
4. Onboard and migrate the application.
5. Optimize the application.

The high-level structure of this process matches the
[Google Cloud migration path](https://cloud.google.com/architecture/migration-to-gcp-getting-started#the_migration_path).
In this case, you follow the migration path to onboard and migrate existing
applications on the IDP.

To ensure that the application onboarding and migration is on the right track,
we recommend that you design validation checkpoints for each phase of the
process, rather than having a single acceptance testing task. Having validation
checkpoints for each phase helps you to promptly detect issues as they arise,
rather than when you are close to the end of the migration.

Even when following a phased process, onboarding and migrating complex
applications to the IDP might require a significant effort, and it might pose
risks. To manage the effort and the risks of onboarding and migrating complex
applications to the IDP, you can follow the onboarding and migration process
iteratively, by migrating parts of the application on each iteration. For
example, if an application is composed of multiple components, you can onboard
and migrate one component for each iteration of the process.

To reduce toil, we recommend that you thoroughly document the application
onboarding and migration process, and make it as self-service as possible, in
line with platform-engineering principles.

In this document, we assume that the onboarding and migration process involves
three teams:

- **Application onboarding and migration team**: the team that's responsible for
  onboarding and migrating the application on the IDP.
- **Application development and operations team**: the team that's responsible
  for developing and operating the application.
- **IDP team**: the team that's responsible for developing and operating the
  IDP.

The following sections describe each phase of the application onboarding and
migration process.

### Intake the onboarding and migration request

The first phase of the application onboarding and migration process is to intake
the request to onboard and migrate the application. The request process is the
following:

1. The application onboarding and migration team files the onboarding and
   migration request.
2. The IDP receives the request, and it recommends existing golden paths.
3. If the IDP can't suggest an existing golden path, the IDP forwards the
   request to the team that manages the IDP for further evaluation.

We recommend that you keep this phase as light as possible by using a form or a
guided, self-service process. For example, you can include migration guidance in
the IDP documentation so that development teams can review it and prepare for
the migration. You can also implement automated checks in your IDP to give
initial feedback to development teams about potential migration blockers and
issues.

To assist and offer consultation to the teams that filed or intend to file an
application onboarding and migration request, we recommend that the team that
manages the IDP establish communication channels to offer assistance to other
teams. For example, the team that manages the IDP might set up dedicated
discussion groups, chat rooms, and office hours where they can offer help and
answer questions about the IDP. To help with onboarding and migration of complex
applications and to facilitate communications, you can also attach a member of
the team that manages the IDP to the application team while the migration is in
progress.

#### Plan application onboarding and migration

As part of this phase, we recommend that the application onboarding and
migration team starts drafting an onboarding and migration plan, even if the
team doesn't have all of the data points to fully define it. When the team
progresses through the assessment phase, they will gather information to
finalize and validate the plan.

To manage the complexity of the migration plan, we recommend that you decompose
it across the following sub-tasks:

- Define the timelines for the onboarding and migration process, and any
  intermediate milestones, according to the requirements of the application
  onboarding and migration. For example, you might develop a countdown plan that
  lists all of the tasks that are required to complete the application
  onboarding and migration, along with responsibilities and estimated duration.
- Define a responsibility assignment (RACI) matrix to clearly outline who is
  responsible for each phase and task that composes the onboarding and migration
  project.
- Monitor the onboarding and migration process, to gather data so that you can
  optimize the process. For example, you might gather data about how much time
  you spend on each phase and on each task of the onboarding and migration
  process. You might also gather data about the most common blockers and issues
  that you experience during the process.

Developing a comprehensive onboarding and migration plan is crucial to the
success of the application onboarding and migration process. Having a plan helps
you to define clear deadlines, assign responsibilities, and deal with
unanticipated issues.

### Assess the application

The second phase of the application onboarding and migration process is to
follow up on the intake request by assessing the application to onboard and
migrate to the IDP. The goal of this assessment phase is to produce the
following artifacts:

- Data about the architecture of the application and its deployment and
  operational processes.
- Plans to migrate the application and onboard it to the IDP.

These outputs of the assessment phase help you to plan and complete the
migration. The outputs also help you to scope the enhancements that the IDP
needs to support the application, and to increase the velocity of future
migrations.

To manage the complexity of the assessment phase, we recommend that you
decompose it into the following steps:

1. Review the application design.
2. Review application dependencies.
3. Review continuous integration and continuous deployment (CI/CD) processes.
4. Review data persistence and data management requirements.
5. Review [FinOps](https://cloud.google.com/learn/what-is-finops) requirements.
6. Review compliance requirements.
7. Review the application team practices.
8. Assess application refactoring and the IDP.
9. Finalize the application onboarding and migration plan.

The preceding steps are described in the following sections. For more
information about assessing applications and defining migration plans, see
[Migrate to Google Cloud: Assess and discover your workloads](https://cloud.google.com/architecture/migration-to-gcp-assessing-and-discovering-your-workloads).

#### Review the application design

To gather a comprehensive understanding about the design of the application, we
recommend that you complete a thorough assessment of the following aspects of
the application:

- **Application source code**:
    - Ensure that the source code of the application is available, and that you
      can access it.
    - Gather information about how many repositories you're using to store the
      source code of the application and the structure of the repositories.
    - Review the deployment descriptors that you're using for the application.
    - Review any code that's responsible for handling provisioning and
      configuration of the necessary infrastructure.
- **Deployable artifacts**: Gather information about the deployable artifacts
  that you're using to package and deploy your application, such as container
  images, packages, and the repositories that you're using to store them.
- **Configuration injection**: Assess how you're injecting configuration inside
  deployable artifacts. For example, gather information about how you're
  distributing environment- and deployment-specific configuration to your
  application.
- **Security requirements**: Collect data about the security requirements and
  processes that you have in place for the application, such as vulnerability
  scanning, binary authorization, bills of materials verification, attestation,
  and secret management.
- **Identity and access management**: Gather information about how your
  application handles identity and access management, and the roles and
  permissions that your application assumes for its users.
- **Observability requirements**:
    - Assess your application's observability requirements, in terms of
      monitoring, logging, tracing and alerting.
    - Gather information about any service level objectives (SLOs) that are in
      place for the application.
- **Availability and reliability requirements**:
    - Gather information about the availability and reliability requirements of
      the application.
    - Define the
      [failure modes](https://cloud.google.com/architecture/migration-to-google-cloud-best-practices#assess_the_failure_modes_that_your_workloads_support)
      that the application supports.
- **Network and connectivity requirements**:
    - Assess the network requirements for your application, such as IP address
      space, DNS names, load balancing and failover mechanisms.
    - Gather information about any connectivity requirements to other
      environments, such as on-premises and third-party ones.
    - Gather information about any other services that your application might
      need, such as API gateways and service meshes.
- **Statefulness**: Develop a comprehensive understanding of how the application
  handles stateful data, if any, and where the application stores data. For
  example, gather information about persistent stateful data, such as data
  stored in databases, object storage services, persistent disks, and transient
  data like caches.
- **Runtime environment requirements**: Gather information about the runtime
  requirements of the application, such as any dependency the application needs
  to run. For example, your application might need certain libraries, or have
  platform or API dependencies.
- **Development tools and environments**. Assess the development tools and
  environments that developers use to support and evolve your application, such
  as integrated development environments (IDEs) along with any IDE extensions,
  the configuration of their development workstations, and any development
  environment they use to support their work.
- **Multi-tenancy requirements**. Gather information about any multi-tenancy
  requirements for the application.

Understanding the application architecture helps you to design and implement an
effective onboarding and migration process for your application. It also helps
you anticipate issues and potential problems that might arise during the
migration. For example, if the architecture of your application to onboard and
migrate to the IDP isn't compatible with your IDP, you might need to spend
additional effort to refactor the application and enhance the IDP.

- #### Review application dependencies

The application to onboard and migrate to the IDP might have dependencies on
systems and data that are outside the scope of the application. To understand
these dependencies, we recommend that you gather information about any reliance
of your application on external systems and data, such as databases, datasets,
and APIs. After you gather information, you classify the dependencies in order
of importance and criticality. For example, your application might need access
to a database to store persistent data, and to external APIs to integrate with
to provide critical functionality to users, while it might have an optional
dependency on a caching system.

Understanding the dependencies of your application on external systems and data
is crucial to plan for continued access to these dependencies during and after
the migration.

#### Review CI/CD processes

After you review the application design and its dependencies, we recommend that
you refine the assessment about your application's deployable artifacts by
reviewing your application's CI/CD processes. These processes usually let you
build the artifacts to deploy the application and let you deploy them in your
runtime environments. For example, you refine the assessment by answering
questions about these CI/CD processes, such as the following:

- Which systems are you using as part of the CI/CD workflows to build and deploy
  your application?
- Where do you store the deployable artifacts that you build for the
  application?
- How frequently do you deploy the application?
- What are your deployment processes like? For example, are you using any
  advanced deployment methodology, such as canary deployments, or blue-green
  deployments?
- Do you need to migrate the deployable artifacts that you previously built for
  the application?

Understanding how the application's CI/CD processes work helps you evaluate
whether your IDP can support these CI/CD processes as is, or if you need to
enhance your IDP to support them. For example, if your application has a
business-critical requirement on a canary deployment process and your IDP
doesn't support it, you might need to factor in additional effort to enhance the
IDP.

#### Review data persistence and data management requirements

By completing the previous tasks of the assessment phase, you gathered
information about the statefulness of the application and about the systems that
the application uses to store persistent and transient data. In this section,
you refine the assessment to develop a deeper understanding of the systems that
the application uses to store stateful data. We recommend that you gather
information on data persistence and data management requirements of your
application. For example, you refine the assessment by answering questions such
as the following:

- Which systems does the application use to store persistent data, such as
  databases, object storage systems, and persistent disks?
- Does the application use any system to store transient data, such as caches,
  in-memory databases, and temporary data disks?
- How much persistent and transient data does the application produce?
- Do you need to migrate any data when you onboard and migrate the application
  to the IDP?
- Does the application depend on any data transformation workflows, such as
  [extract, transform, and load (ETL)](https://en.wikipedia.org/wiki/Extract,_transform,_load)
  jobs?

Understanding your application's data persistence and data management
requirements helps you to ensure that your IDP and your production environment
can effectively support the application. This understanding can also help you
determine whether you need to enhance the IDP.

#### Review FinOps requirements

As part of the assessment of your application, we recommend that you gather data
about the FinOps requirements of your application, such as budget control and
cost management, and evaluate whether your IDP supports them. For example, the
application might require certain mechanisms to control spending and manage
costs, eventually sending alerts. The application might also require mechanisms
to completely stop spending when it reaches a certain budget limit.

Understanding your application's FinOps requirements helps you to ensure that
you keep your application costs under control. It also helps you to establish
proper cost attribution and cost optimization practices.

#### Review compliance requirements

The application to onboard and migrate to the IDP and its runtime environment
might have to meet compliance requirements, especially in regulated industries.
We recommend that you assess the compliance requirements of the application, and
evaluate if the IDP already supports them. For example, the application might
require isolation from other workloads, or it might have data locality
requirements.

Understanding your application's compliance requirements helps you to scope the
necessary refactoring and enhancements for your application and for the IDP.

#### Review the application team practices

After you review the application, we recommend that you gather information about
team practices and the methodologies for developing and operating the
application. For example, the team might already have adopted DevOps principles,
they might be already implementing Site Reliability Engineering (SRE), or they
might be already familiar with platform engineering and with the IDP.

By gathering information about the team that develops and operates the
application to migrate, you gain insights about the experience and the maturity
of that team. You also learn whether there's a need to spend effort to train
team members to proficiently use the IDP.

#### Assess application refactoring and the IDP

After you gather information about the application, its development and
operation teams, and its requirements, you evaluate the following:

- Whether the application will work as-is if migrated and onboarded to the IDP.
- Whether the IDP can support the application to onboard and migrate.

The goal of this task is to answer the following questions:

1. Does the application need any refactoring to onboard and migrate it to the
   IDP?
2. Are there any new services or processes that the IDP should offer to migrate
   the application?
3. Does the IDP meet the compliance and regulatory requirements that the
   application requires?

By answering these questions, you focus on evaluating potential onboarding and
migration blockers. For example, you might experience the following onboarding
and migration blockers:

- If the application doesn't meet the observability or configurability
  requirements of the IDP, you might need to enhance the application to meet
  those requirements. For example, you might need to refactor the application to
  expose a set of metrics on a given endpoint, or to accept configuration
  injection as supported by the IDP.
- If the application relies on dependencies that suffer from known security
  vulnerabilities, you might need to spend effort to update vulnerable
  dependencies or to mitigate the vulnerabilities.
- If the application has a critical dependency on a service that the IDP doesn't
  offer, you might need to refactor the application to avoid that dependency, or
  you might consider extending the IDP to offer that service.
- If the application depends on a self-managed service that the IDP also offers
  as a managed service, you might need to refactor the application to migrate
  from the self-managed service to the managed service.

The application development and operations team is responsible for the
application refactoring tasks.

When you scope the eventual enhancements that the IDP needs to support the
application, we recommend that you frame these enhancements in the broader
vision that you have for the IDP, and not as a standalone exercise. We also
recommend that you consider your IDP as a product for which you should develop a
path to success. For example, if you're considering adding a new service to the
IDP, we recommend that you evaluate how that service fits in the path to success
for your IDP, in addition to the technical feasibility of the initiative.

By assessing the refactoring effort that's required to onboard and migrate the
application, you develop a comprehensive understanding of the tasks that you
need to complete to refactor the application and how you need to enhance the IDP
to support the application.

#### Finalize the application onboarding and migration plan

To complete the assessment phase, you finalize the application onboarding and
migration plan with consideration of the data that you gathered. To finalize the
plan, you do the following:

- Develop a rollback strategy for each task to recover from unanticipated issues
  that might arise during the application onboarding and migration.
- Define criteria to safely retire the environment where the application runs
  before you onboard and migrate it to the IDP. For example, you might require
  that the application works as expected after onboarding and migrating it to
  the IDP before you retire the old environment.
- Validate the migration plan to help you avoid unanticipated issues. For more
  information about validating a migration plan, see
  [Migrate to Google Cloud: Best practices for validating a migration plan](https://cloud.google.com/architecture/migration-to-google-cloud-best-practices).

### Set up the IDP

After you complete the assessment phase, you use its outputs to:

1. Enhance the IDP by adding missing features and services.
2. Configure the IDP to support the application.

#### Enhance the IDP

During the assessment phase, you scope any enhancements to the IDP that it needs
to support the application and how those enhancements fit in your plans for the
IDP. By completing this task, you design and implement the enhancements. For
example, you might need to enhance the IDP as follows:

- Add services to the IDP, in case the application has critical dependencies on
  such services, and you can't refactor the application. For example, if the
  application needs an in-memory caching service and the IDP doesn't offer that
  service yet, you can add a data store like Cloud Memorystore to the IDP's
  portfolio of services.
- Meet the application's compliance requirements. For example, if the
  application requires that its data must reside in certain geographic regions
  and the IDP doesn't support deploying resources in those regions, you need to
  enhance the IDP to support those regions.
- Support further configurability and observability to cover the application's
  requirements. For example, if the application requires monitoring certain
  metrics, and the IDP doesn't support those metrics, you might enhance the
  configuration injection and observability services that the IDP provides.

By enhancing the IDP to support the application, you unblock the migration. You
also help streamline processes for onboarding and migration projects for other
applications that might need those IDP enhancements.

#### Configure the IDP

After you enhance the IDP, if needed, you configure it to provide the resources
that the application needs. For example, you configure the following IDP
services for the application, or a subset of services:

- Foundational services, such as
  [Google Cloud folders and projects](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy),
  Identity and access management (IAM), network connectivity, Virtual Private
  Cloud (VPC), and DNS zones and records.
- Compute resources, such as Google Kubernetes Engine clusters, and Cloud Run
  services.
- Data management resources, such as Cloud SQL databases and DataFlow jobs.
- Application-level services, such as API gateways, Cloud Service Mesh, and
  Cloud Storage buckets.
- Application delivery services, such as source code repositories, and Artifact
  Registry repositories.
- AI/ML services, such as Vertex AI.
- Messaging and event processing services, such as Cloud Pub/Sub and Eventarc.
- Instrument observability services, such as Cloud Operations Suite.
- Security and secret management services, such as Cloud Key Management Service
  and Secret Manager.
- Cost management and FinOps services, such as Cloud Billing.

By configuring the IDP, you prepare it to host the application that you want to
onboard and migrate.

### Onboard and migrate the application

In this phase, you onboard and migrate the application to the IDP by completing
the following tasks:

1. Refactor the application to apply the changes that are necessary to onboard
   and migrate it on the IDP.
2. Configure CI/CD workflows for the application and deploy the application in
   the development environment.
3. Promote the application from the development environment to the staging
   environment.
4. Perform acceptance testing.
5. Migrate data from the source environment to the production environment.
6. Promote the application from the staging environment to the production
   environment and ensure the application's operational readiness.
7. Perform the cutover from the source environment.

By completing the preceding tasks, you onboard and migrate the application to
the IDP. The following sections describe these tasks in more detail.

#### Refactor the application

In the assessment phase, you scoped the refactoring that your application needs
in order to onboard and migrate it to the IDP. By completing this task, you
design and implement the refactoring. For example, you might need to refactor
your application in the following ways in order to meet the IDP's requirements:

- Support the IDP's configuration mechanisms. For example, the IDP might
  distribute configuration to applications using environment variables or
  templated configuration files.
- Refactor the existing application observability mechanisms, or implement them
  if there are none, to meet the IDP's observability requirements. For example,
  the IDP might require that applications expose a defined set of metrics to
  observe.
- Update the application's dependencies that suffer from known vulnerabilities.
  For example, you might need to update operating system packages and software
  libraries that suffer from known vulnerabilities.
- Avoid dependencies on services that the IDP doesn't offer. For example, if the
  application depends on an object storage service that the IDP doesn't support,
  you might need to refactor the application to migrate to a supported object
  storage service, such as Cloud Storage.
- Migrate from self-managed services to IDP services. For example, if your
  application depends on a self-managed database, you might refactor it to use a
  database service that the IDP offers, such as Cloud SQL.

By refactoring the application, you prepare it to onboard and migrate it on the
IDP.

#### Configure CI/CD workflows

After you refactor the application, you do the following:

1. Configure CI/CD workflows to deploy the application.
2. Optionally migrate deployable artifacts from the source environment.
3. Deploy the application in the development environment.

##### Configure CI/CD workflows to deploy the application

To build deployable artifacts and deploy them in your runtime environments, we
recommend that you avoid manual processes. Instead of manual processes,
configure CI/CD workflows by using the application delivery services that the
IDP provides and store deployable artifacts in IDP-managed artifact
repositories. For example, you can configure CI/CD workflows by using the
following methods:

1. Configure Cloud Build to
   [build container images and store them in Artifact Registry](https://cloud.google.com/build/docs/building/build-containers).
2. Configure a
   [Cloud Deploy pipeline to automate delivery of your application](https://cloud.google.com/deploy/docs/overview).

When you build the CI/CD workflows for your environment, consider how many
runtime environments the IDP supports. For example, the IDP might support
different runtime environments that are isolated from each other such as the
following:

- **Development environment**: for development and testing.
- **Staging environment**: for validation and acceptance testing.
- **Production environment**: for your production workloads.

If the IDP supports multiple runtime environments for the application, you need
to configure the CI/CD workflows for the application to support promoting the
application's deployable artifact. You should plan for promoting the application
from development to staging, and then from staging to production.

When you promote the application from one environment to the next environment,
we recommend that you avoid rebuilding the application's deployable artifacts.
Rebuilding creates new artifacts, which means that you would be deploying
something different than what you tested and validated.

##### Migrate deployable artifacts from the source environment

If you need to support rolling back to previous versions of the application, you
can migrate previous versions of the deployable artifacts that you built for the
application from the source environment to an IDP-managed artifact repository.
For example, if your application is containerized, you can migrate the container
images that you built to deploy the application
[to Artifact Registry](https://cloud.google.com/artifact-registry/docs/docker/migrate-external-containers).

##### Deploy the application in the development environment

After configuring CI/CD workflows to build deployable artifacts for the
application and to promote them from one environment to another, you deploy the
application in the development environment using the CI/CD workflows that you
configured.

By using CI/CD workflows to build deployable artifacts and deploy the
application, you avoid manual processes that are less repeatable and more prone
to errors. You also validate that the CI/CD workflows work as expected.

#### Promote from development to staging

To promote your application from the development environment to the staging
environment, you do the following:

1. Test the application and verify that it works as expected.
2. Fix any unanticipated issues.
3. Promote the application from the development environment to the staging
   environment.

By promoting the application from the development environment to the staging
environment, you accomplish the following:

- Complete a first set of validation tasks.
- Polish the application by fixing unanticipated issues.
- Enable your teams for broader and deeper functional and non-functional testing
  of the application in the staging environment.

#### Perform acceptance testing

After you promote the application to your staging environment, you perform
extensive acceptance testing for both functional and non-functional
requirements. When you perform acceptance testing, we recommend that you
validate that the user journeys and the business processes that the application
implements are working properly in situations that resemble real-world usage
scenarios. For example, when you perform acceptance testing, you can do the
following:

- Evaluate whether the application works on data that's similar in scope and
  size to production data. For example, you can periodically populate your
  staging environment with data from the production environment.
- Ensure that the application can handle production-like traffic. For example,
  you can mirror production traffic and direct it to the application in the
  staging environment.
- Validate that the application works as designed under degraded conditions. For
  example, in your staging environment you can artificially cause outages and
  break connectivity to other systems and evaluate whether the application
  respects its failure mode. This testing lets you verify that the application
  recovers after you terminate the outage, and that it restores connectivity.
- Verify that the application, the staging environment, and the production
  environment meet your compliance requirements, such as locality restrictions,
  licensing, and auditability.

Acceptance testing helps you ensure that the application works as expected in an
environment that resembles the production environment, and helps you identify
unanticipated issues.

#### Migrate data

After you complete acceptance testing for the application, you migrate data from
the source environment to IDP-managed services such as the following:

- Migrate data from databases in the source environment to IDP-managed
  databases.
- Migrate data from object storage services to IDP-managed object storage
  services.

To migrate data from your source environment to IDP-managed services, you can
choose approaches like the following, depending on your requirements:

- **Scheduled maintenance**: Also called _one-time migration_ or _offline
  migration_, with this approach you migrate data during scheduled maintenance
  when your application can afford the downtime represented by a planned
  cut-over window.
- **Continuous replication**: Also called _continuous migration_ or _online
  migration_, continuous replication builds the scheduled maintenance approach
  to reduce the cut-over window size. The size reduction is possible because you
  provide a continuous replication mechanism after the initial data copy and
  validation.
- **Y (writing and reading)**: Also called _parallel migration_, this approach
  is suitable for applications that cannot afford the downtime that's
  represented by a cut-over window, even if small. By following this approach,
  you refactor the application to write data to both the source environment and
  to IDP-managed services. Then, when you're ready to migrate, you switch to
  reading data from IDP-managed services.
- **Data-access microservice**: This approach builds on the Y (writing and
  reading) approach by centralizing data read and write operations in a scalable
  microservice.

Each of the preceding approaches focuses on solving specific issues, and there's
no approach that's inherently better than the others. For more information about
migrating data to Google Cloud and choosing the best data migration approach for
your application, see
[Migrate to Google Cloud: Transfer your large datasets](https://cloud.google.com/architecture/migration-to-google-cloud-transferring-your-large-datasets).

I your data is stored in services managed by other cloud providers, see the
following resources:

- [Migrate from AWS to Google Cloud: Get started](https://cloud.google.com/architecture/migration-from-aws-get-started)
- Migrate from Azure to Google Cloud: Get started

Migrating data from one environment to another is a complex task. If you think
that the data migration is too complex to handle it as part of the application
onboarding and migration process, you might consider migrating data as part of a
dedicated migration project.

#### Promote from staging to production

After you complete data migration and acceptance testing, you promote the
application to the production environment. To complete this task, you do the
following:

1. Promote the application from the staging environment to the production
   environment. The process is similar to when you promoted the application from
   the development environment to the staging environment: you use the
   IDP-managed CI/CD workflows that you configured for the application to
   promote it from the staging environment to the production environment.
2. Ensure the application's operational readiness. For example, to help you
   avoid performance issues if the application requires a cache, ensure that the
   cache is properly initialized.
3. Fix any unanticipated issues.

When you check the application's operational readiness before you promote it
from the staging environment to the production environment, you ensure that the
application is ready for the production environment.

#### Perform the cutover

After you promote the application to the production environment and ensure that
it works as expected, you configure the production environment to gradually
route requests for the application to the newly promoted application release.
For example, you can implement a
[canary deployment strategy that uses Cloud Deploy](https://cloud.google.com/deploy/docs/deployment-strategies/canary).

After you validate that the application continues to work as expected while the
number of requests to the newly promoted application increases, you do the
following:

1. Configure your production environment to route all of the requests to your
   newly promoted application.
2. Retire the application in the source environment.

Before you retire the application in the source environment, we recommend that
you prepare backups and a rollback plan. Doing so will help you handle
unanticipated issues that might force you to go back to using the source
environment.

### Optimize the application

Optimization is the last phase of the onboarding and migration process. In this
phase, you iterate on optimization tasks until your target environment meets
your optimization requirements. For each iteration, you do the following:

1. Assess your current environment, teams, and optimization loop.
2. Establish your optimization requirements and goals.
3. Optimize your environment and your teams.
4. Tune the optimization loop.

You repeat the preceding sequence until you achieve your optimization goals.

For more information about optimizing your Google Cloud environment, see
[Migrate to Google Cloud: Optimize your environment](https://cloud.google.com/architecture/migration-to-google-cloud-optimizing-your-environment)
and
[Google Cloud Architecture Framework: Performance optimization](https://cloud.google.com/architecture/framework/performance-optimization).

The following sections integrate the considerations in Migrate to Google Cloud:
Optimize your environment.

#### Establish your optimization requirements

Optimization requirements help you to narrow the scope of the current
optimization iteration. To establish your optimization requirements for the
application, start by considering the following aspects:

- **Security, privacy, and compliance**: help you enhance the security posture
  of your environment.
- **Reliability**: help you improve the availability, scalability, and
  resilience of your environment.
- **Cost optimization**: help you to optimize the resource consumption and
  resulting cost of your environment.
- **Operational efficiency**: help you maintain and operate your environment
  efficiently.
- **Performance optimization**: help you optimize the performance of the
  workloads that are deployed in your environment.

For each aspect, we recommend that you establish your optimization requirements
for the application. Then, you set measurable optimization goals to meet those
requirements. For more information about optimization requirements and goals,
see
[Establish your optimization requirements and goals](https://cloud.google.com/architecture/migration-to-google-cloud-optimizing-your-environment#establish_your_optimization_requirements_and_goals).

After you realize the optimization requirements for the application, you
completed the onboarding and migration process for the application.

## Optimize the onboarding and migration process and the IDP

After you onboard and migrate the application, you use the data that you
gathered about the process and about the IDP to refine and optimize the process.
Similarly to the optimization phase for your application, you complete the tasks
that are described in the optimization phase, but with a focus on the onboarding
and migration process and on the IDP.

### Establish your optimization requirements for the IDP

To narrow down the scope to optimize the onboarding and migration process, and
the IDP, you establish optimization requirements according to data you gather
while running through the process. For example, during the onboarding and
migration of an application, you might face unanticipated issues that involve
the process and the IDP, such as:

- Missing documentation about the process
- Missing data to complete tasks
- Tasks that take too much time to complete
- Unclear responsibility mapping
- Suboptimal information sharing
- Lack of stakeholder engagement
- IDP not supporting one or more application use cases
- IDP lacking support for one or more services
- IDP lacking support for the application's multi-tenancy requirements
- IDP not working as expected and documented
- Absence of golden paths to for the application

To address the issues that arise while you're onboarding and migrating an
application, you establish optimization requirements. For example, you might
establish the following optimization requirements to address the example issues
described above:

- Refine the documentation about the IDP and the onboarding and migration
  process to include any missing information about the process and its tasks.
- Simplify the onboarding and migration process to remove unnecessary tasks, and
  automate as many tasks as possible.
- Validate that the process accounts for a responsibility assignment that fully
  covers the application, the IDP, and the process itself.
- Reduce adoption friction by temporarily assigning members of the IDP team to
  application teams to act as IDP adoption coaches and consultants.
- Refine existing golden paths, or create new ones to cover the application
  onboarding and migration.
- Reduce adoption friction by implementing a tiered onboarding and migration
  process. Each tier would have a different set of requirements according to the
  tier. For example, a higher tier would have more stringent requirements than a
  lower tier.

After establishing optimization requirements, you set measurable optimization
goals to meet those requirements. For more information about optimization
requirements and goals, see
[Establish your optimization requirements and goals](https://cloud.google.com/architecture/migration-to-google-cloud-optimizing-your-environment#establish_your_optimization_requirements_and_goals).

## Application onboarding and migration example

In this section, you explore how the onboarding and migration process looks like
for an example. The example that we describe in this section doesn't represent a
real production application.

To reduce the scope of the example, we focus the example on the following
environments:

- Source environment: Amazon Elastic Kubernetes Service (Amazon EKS)
- Target environment: GKE

This document focuses on the onboarding and migration process. For more
information about migrating from Amazon EKS to GKE, see
[Migrate from AWS to Google Cloud: Migrate from Amazon EKS to GKE](https://cloud.google.com/architecture/migrate-amazon-eks-to-gke).

To onboard and migrate the application on the IDP, you follow the
[onboarding and migration process](#application-onboarding-and-migration-process).

### Intake the onboarding and migration request (example)

In this example, the application onboarding and migration team files a request
to onboard and migrate the application on the IDP. To fully present the
onboarding and migration process, we assume that IDP cannot find an existing
golden path to suggest to onboard and migrate the application, so it forwards
the request to the team that manages the IDP for further evaluation.

#### Plan application onboarding and migration (example)

To define timelines and milestones to onboard and migrate the application on the
IDP, the application onboarding and migration team prepares a countdown plan:

| Phase                               | Task                                                          | Countdown \[days\] | Status        |
| :---------------------------------- | :------------------------------------------------------------ | :----------------- | :------------ |
| Assess the application              | Review the application design                                 | \-27               | Not started   |
|                                     | Review application dependencies                               | \-23               | Not started   |
|                                     | Review CI/CD processes                                        | \-21               | Not started   |
|                                     | Review data persistence and data management requirements      | \-21               | Not started   |
|                                     | Review FinOps requirements                                    | \-20               | Not started   |
|                                     | Review compliance requirements                                | \-20               | Not started   |
|                                     | Review the application's team practices                       | \-19               | Not started   |
|                                     | Assess application refactoring and the IDP                    | \-19               | Not started   |
|                                     | Finalize the application onboarding and migration plan        | \-18               | Not started   |
| Set up the IDP                      | Enhance the IDP                                               | N/A                | Not necessary |
|                                     | Configure the IDP                                             | \-17               | Not started   |
| Onboard and migrate the application | Refactor the application                                      | \-15               | Not started   |
|                                     | Configure CI/CD workflows                                     | \-9                | Not started   |
|                                     | Promote from development to staging                           | \-6                | Not started   |
|                                     | Perform acceptance testing                                    | \-5                | Not started   |
|                                     | Migrate data                                                  | \-3                | Not started   |
|                                     | Promote from staging to production                            | \-1                | Not started   |
|                                     | Perform the cutover                                           | 0                  | Not started   |
| Optimize the application            | Assess your current environment, teams, and optimization loop | 1                  | Not started   |
|                                     | Establish your optimization requirements and goals            | 1                  | Not started   |
|                                     | Optimize your environment and your teams                      | 3                  | Not started   |
|                                     | Tune the optimization loop                                    | 5                  | Not started   |

To clearly outline responsibility assignments, the application onboarding and
migration team defines the following RACI matrix for each phase and task of the
process:

| Phase                               | Task                                                          | Application onboarding and migration team | Application development and operations team | IDP team    |
| :---------------------------------- | :------------------------------------------------------------ | :---------------------------------------- | :------------------------------------------ | :---------- |
| Assess the application              | Review the application design                                 | Responsible                               | Accountable                                 | Informed    |
|                                     | Review application dependencies                               | Responsible                               | Accountable                                 | Informed    |
|                                     | Review CI/CD processes                                        | Responsible                               | Accountable                                 | Informed    |
|                                     | Review data persistence and data management requirements      | Responsible                               | Accountable                                 | Informed    |
|                                     | Review FinOps requirements                                    | Responsible                               | Accountable                                 | Informed    |
|                                     | Review compliance requirements                                | Responsible                               | Accountable                                 | Informed    |
|                                     | Review the application's team practices                       | Responsible                               | Accountable                                 | Informed    |
|                                     | Assess application refactoring and the IDP                    | Responsible                               | Accountable                                 | Consulted   |
|                                     | Plan application onboarding and migration                     | Responsible                               | Accountable                                 | Consulted   |
| Set up the IDP                      | Enhance the IDP                                               | Accountable                               | Consulted                                   | Responsible |
|                                     | Configure the IDP                                             | Responsible, Accountable                  | Consulted                                   | Consulted   |
| Onboard and migrate the application | Refactor the application                                      | Accountable                               | Responsible                                 | Consulted   |
|                                     | Configure CI/CD workflows                                     | Responsible, Accountable                  | Consulted                                   | Consulted   |
|                                     | Promote from development to staging                           | Responsible, Accountable                  | Consulted                                   | Informed    |
|                                     | Perform acceptance testing                                    | Responsible, Accountable                  | Consulted                                   | Informed    |
|                                     | Migrate data                                                  | Responsible, Accountable                  | Consulted                                   | Consulted   |
|                                     | Promote from staging to production                            | Responsible, Accountable                  | Consulted                                   | Informed    |
|                                     | Perform the cutover                                           | Responsible, Accountable                  | Consulted                                   | Informed    |
| Optimize the application            | Assess your current environment, teams, and optimization loop | Informed                                  | Responsible, Accountable                    | Informed    |
|                                     | Establish your optimization requirements and goals            | Informed                                  | Responsible, Accountable                    | Informed    |
|                                     | Optimize your environment and your teams                      | Informed                                  | Responsible, Accountable                    | Informed    |
|                                     | Tune the optimization loop                                    | Informed                                  | Responsible, Accountable                    | Informed    |

### Assess the application (example)

In the assessment phase, the application onboarding and migration team assesses
the application by completing the assessment phase tasks.

#### Review the application design (example)

The application onboarding and migration team reviews the application design,
and gathers the following information:

1. **Application source code**. The application source code is available on the
   company source code management and hosting solution.
2. **Deployable artifacts**. The application is fully containerized using a
   single Open Container Initiative (OCI) container image. The container image
   uses Debian as a base image.
3. **Configuration injection**. The application supports injecting configuration
   using environment variables and configuration files. Environment variables
   take precedence over configuration files. The application reads runtime- and
   environment-specific configuration from a Kubernetes ConfigMap.
4. **Security requirements**. Container images need to be scanned for
   vulnerabilities. Also, container images need to be verified for authenticity
   and bills of materials. The application requires periodic secret rotation.
   The application doesn't allow direct access to its production runtime
   environment.
5. **Identity and access management**. The application requires a dedicated
   service account with the minimum set of permissions to work correctly.
6. **Observability requirements**. The application logs messages to stout and
   stderr streams, and exposes metrics and tracing in OpenTelemetry format. The
   application requires SLO monitoring for uptime and request error rates.
7. **Availability and reliability requirements**. The application is not
   business critical, and can afford two hours of downtime at maximum. The
   application is designed to shed load under degraded conditions, and is
   capable of automated recovery after a loss of connectivity.
8. **Network and connectivity requirements**. The application needs:

    - A /28 IPv4 subnet to account for multiple instances of the application.
    - A DNS name for each instance of the application.
    - Connectivity to its data storage systems.
    - Load balancing across several application instances.

    The application doesn't require any specific service mesh configuration.

9. **Statefulness**. The application stores persistent data on Amazon Relational
   Database Service (Amazon RDS) for PostgreSQL and on Amazon Simple Storage
   Service (Amazon S3).
10. **Runtime environment requirements**. The application doesn't depend on any
    preview Kubernetes features, and doesn't need dependencies outside what is
    packaged in its container image.
11. **Development tools and environments**. The application doesn't have any
    dependency on specific IDEs or development hardware.
12. **Multi-tenancy requirements**. The application doesn't have any
    multi-tenancy requirements.

#### Review application dependencies (example)

The application onboarding and migration team reviews dependencies on systems
that are outside the scope of the application, and gathers the following
information:

- **Internal corporate APIs**. The application queries two corporate APIs
  through the IDP API gateway.

#### Review CI/CD processes (example)

The application onboarding and migration team reviews the application's CI/CD
processes, and gathers the following information:

- A GitHub Action builds deployable artifacts for the application, and stores
  artifacts in an Amazon Elastic Container Repository (Amazon ECR).
- There is no CD process. To deploy a new version of the application, the
  application development and operations team manually runs a scripted workflow
  to deploy the application on Amazon EKS.
- There is no deployment schedule. The application development and operations
  team runs the deployment workflow on demand. In the last two years, the team
  deployed the application twice a month, on average.
- The deployment process doesn't implement any advanced deployment methodology.
- There is no need to migrate deployable artifacts that the CI process built for
  previous versions of the application.

#### Review data persistence and data management requirements (example)

The application onboarding and migration team reviews data persistence and data
management requirements, and gathers the following information:

- **Amazon RDS for PostgreSQL**. The application stores and reads data from
  three PostgreSQL databases that reside on a single, high-availability Amazon
  RDS for PostgreSQL instance. The application uses standard PostgreSQL
  features.
- **Amazon S3**. The application stores and reads objects in two Amazon S3
  buckets.

The application onboarding and migration team is also tasked to migrate data
from Amazon RDS for PostgreSQL and Amazon S3 to database and object storage
services offered by the IDP. In this example, the IDP offers Cloud SQL for
PostgreSQL as a database service, and Cloud Storage as an object storage
service.

As part of this application dependency review, the application onboarding and
migration team assesses the application's Amazon RDS database and the Amazon S3
buckets. For simplicity, we omit details about those assessments from this
example. For more information about assessing Amazon RDS and Amazon S3, see the
_Assess the source environment_ sections in the following documents:

- [Migrate from AWS to Google Cloud: Migrate from Amazon RDS and Amazon Aurora for PostgreSQL to Cloud SQL and AlloyDB for PostgreSQL](https://cloud.google.com/architecture/migrate-aws-rds-aurora-to-postgresql)
- [Migrate from AWS to Google Cloud: Migrate from Amazon S3 to Cloud Storage](https://cloud.google.com/architecture/migrate-amazon-s3-to-cloud-storage)

#### Review FinOps requirements (example)

The application onboarding and migration team reviews FinOps requirements, and
gathers the following information:

- The application must not exceed ten thousands USD of maximum aggregated
  spending per month.

#### Review compliance requirements (example)

The application onboarding and migration team reviews compliance requirements,
and gathers the following information:

- The application doesn't need to meet any compliance requirements to regulate
  data residency and network traffic.

#### Review the application's team practices

The application onboarding and migration team reviews development and
operational practices that the application development and operations team has
in place, and gathers the following information:

- The team started following an agile development methodology one year ago.
- The team is exploring SRE practices, but didn't implement anything in that
  regard yet.
- The team doesn't have any prior experience with the IDP.

The application onboarding and migration team suggests the following:

- Train the application development and operations team on basic platform
  engineering concepts.
- Train the team on the architecture of the IDP, how to use the IDP effectively.
- Consult with the IDP team to assess potential changes to development and
  operational processes after migrating the application on the IDP.

#### Assess application refactoring and the IDP (example)

After reviewing the application and its related CI/CD process, the team
application onboarding and migration team assesses the refactoring that the
application needs to onboard and migrate it on the IDP, scopes the following
refactoring tasks:

- Support reading objects from objects and writing objects to the IDP's object
  storage service. In this example, the IDP offers Cloud Storage as an object
  storage service. For more information about refactoring workloads when
  migrating from Amazon S3 to Cloud Storage, see the
  [_Migrate data and workloads from Amazon S3 to Cloud Storage_ section](https://cloud.google.com/architecture/migrate-amazon-s3-to-cloud-storage#migrate-data-and-workloads-from-amazon-s3-to-cloud-storage)
  in Migrate from AWS to Google Cloud: Migrate from Amazon S3 to Cloud Storage.
- Update the application configuration to use Cloud SQL for PostgreSQL instead
  of Amazon RDS for PostgreSQL.
- Support exporting the metrics that the IDP needs to support observability for
  the application.
- Update the application dependencies to versions that are not impacted by known
  vulnerabilities.

The application onboarding and migration team evaluates the IDP against the
application's requirements, and concludes that:

- The IDP's current set of services is capable of supporting the application, so
  there is no need to extend the IDP to offer additional services.
- The IDP meets the application's compliance and regulatory requirements.

#### Finalize the application onboarding and migration plan (example)

After completing the application review, the application onboarding and
migration team refines the onboarding and migration plan, and validates it in
collaboration with technical and non-technical stakeholders.

### Set up the IDP (example)

After you assess the application and plan the onboarding and migration process,
you set up the IDP.

#### Enhance the IDP (example)

The IDP team doesn't need to enhance the IDP to onboard and migrate the
application because:

- The IDP already offers all the services that the application needs.
- The IDP meets the application's compliance and regulatory requirements.
- The IDP meets the application's configurability and observability
  requirements.

#### Configure the IDP (example)

The application onboarding and migration team configures the runtime
environments for the application using the IDP: a development environment, a
staging environment, and a production environment. For each environment, the
application onboarding and migration team completes the following tasks:

1. Configures foundational services:

    1. Creates a new Google Cloud project.
    2. Configures IAM roles and service accounts.
    3. Configures a VPC and a subnet.
    4. Creates DNS records in the DNS zone.

2. Provisions and configures a GKE cluster for the application.
3. Provisions and configures a Cloud SQL for PostgreSQL instance.
4. Provisions and configures two Cloud Storage buckets.
5. Provisions and configures an Artifact Registry repository for container
   images.
6. Instruments Cloud Operations Suite to observe the application.
7. Configures Cloud Billing budget and budget alerts for the application.

### Onboard and migrate the application (example)

To onboard and migrate the application, the application development and
operations team refactors the application and then the application onboarding
and migration team proceeds with the onboarding and migration process.

#### Refactor the application (example)

The application development and operations team refactors the application as
follows:

1. Refactors the application to read from and write objects to Cloud Storage,
   instead of Amazon S3.
2. Updates the application configuration to use the Cloud SQL for PostgreSQL,
   instance instead of the Amazon RDS for PostgreSQL instance.
3. Exposes the metrics that the IDP needs to observe the application.
4. Update application dependencies that are affected by known vulnerabilities.

#### Configure CI/CD workflows (example)

To configure CI/CD workflows, the application onboarding and migration team does
the following:

1. Refactors the application CI workflow to push container images to the
   Artifact Registry repository, in addition to Amazon ECR.
2. Implements a Cloud Deploy pipeline to automatically deploy the application,
   and promote it across runtime environments.
3. Deploys the application in the development environment using the Cloud Deploy
   pipeline.

#### Promote the application from development to staging

After deploying the application in the development environment, the application
onboarding and migration team:

1. Tests the application, and verifies that it works as expected.
2. Promotes the application from the development environment to the staging
   environment.

#### Perform acceptance testing (example)

After promoting the application from the development environment to the staging
environment, the application onboarding and migration team performs acceptance
testing.

To perform acceptance testing to validate the application's real-world user
journeys and business processes, the application onboarding and migration team
consults with the application development and operations team.

The application onboarding and migration team performs acceptance testing as
follows:

1. Ensures that the application works as expected when dealing with amounts of
   data and traffic that are similar to production ones.
2. Validates that the application works as designed under degraded conditions,
   and that it recovers once the issues are resolved. The application onboarding
   and migration team tests the following scenarios:

    - Loss of connectivity to the database
    - Loss of connectivity to the object storage
    - Degradation of the CI/CD pipeline that blocks deployments
    - Tentative exploitation of short-lived credentials, such as access tokens
    - Excessive application load

3. Verifies that observability and alerting for the application are correctly
   configured.

#### Migrate data (example)

After completing acceptance testing for the application, the application
onboarding and migration team migrates data from the source environment to the
Google Cloud environment as follows:

1. Migrate data from Amazon RDS for PostgreSQL to Cloud SQL for PostgreSQL.
2. Migrate data from Amazon S3 to Cloud Storage.

For simplicity, this document doesn't describe the details of migrating from
Amazon RDS and Amazon S3 to Google Cloud. For more information about migrating
from Amazon RDS and Amazon S3 to Google Cloud, see:

- [**Migrate from AWS to Google Cloud: Migrate from Amazon S3 to Cloud Storage**](https://cloud.google.com/architecture/migrate-amazon-s3-to-cloud-storage)
- [Migrate from AWS to Google Cloud: Migrate from Amazon RDS and Amazon Aurora for PostgreSQL to Cloud SQL and AlloyDB for PostgreSQL](https://cloud.google.com/architecture/migrate-aws-rds-aurora-to-postgresql)

#### Promote from staging to production (example)

After performing acceptance testing and after migrating data to the Google Cloud
environment, the application onboarding and migration team:

1. Promotes the application from the staging environment to the production
   environment using the Cloud Deploy pipeline.
2. Ensures the application's operational readiness by verifying that the
   application:

- Correctly connects to the Cloud SQL for PostgreSQL instance
    - Has access to the Cloud Storage buckets
    - Exposes endpoints through Cloud Load Balancing

#### Perform the cutover (example)

After promoting the application to the production environment, and ensuring that
the application is operationally ready, the application onboarding and migration
team:

1. Configures the production environment to gradually route requests to the
   application in 5% increments, until all the requests are routed to the Google
   Cloud environment.
2. Refactors the CI workflow to push container images to Artifact Registry only.
3. Takes backups to ensure that a rollback is possible, in case of unanticipated
   issues.
4. Retires the application in the source environment.

### Optimize the application (example)

After performing the cutover, the application development and operations team
takes over the maintenance of the application, and establishes the following
optimization requirements:

- Refine the CD process by adopting a canary deployment methodology.
- Reduce the application's operational costs by:

    - Tuning the configuration of the GKE cluster
    - Enabling the Cloud Storage Autoclass feature

After establishing optimization requirements, the application development and
operations team completes
[the rest of the tasks of the optimization phase](#optimize-the-application).

## What's next

- Learn how to
  [Migrate from Amazon EKS to Google Kubernetes Engine (GKE)](https://cloud.google.com/architecture/migrate-amazon-eks-to-gke).
- Learn when to
  [find help for your migrations](https://cloud.google.com/architecture/migration-to-gcp-getting-started#finding_help).

### Contributors

Authors:

- [Marco Ferrari](https://www.linkedin.com/in/ferrarimark) | Cloud Solutions
  Architect
- [Paul Revello](https://www.linkedin.com/in/paul-revello) | Cloud Solutions
  Architect

Other contributors:

- [Ben Good](https://www.linkedin.com/in/benjamingood) | Solutions Architect
- [Shobhit Gupta](https://www.linkedin.com/in/shobhit-gupta-3b1a5078) |
  Solutions Architect
- James Brookbank | Solutions Architect
