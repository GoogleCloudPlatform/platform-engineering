# Google Cloud Workstations

This plugin allows you to link [GCP Cloud Workstations](https://cloud.google.com/workstations/docs/overview) with Backstage components.

<img src="./docs/gcpworkstations_card.png" width="800">

<img src="./docs/gcpworkstations_page.png" width="800">


## Prerequisites

Installation of the following packages are needed before building:

- [node-gyp](https://github.com/nodejs/node-gyp)

## Local installation instructions

### Clone the plugin repository on a local folder

```bash
mkdir ./backstage-local-plugins-install
cd ./backstage-local-plugins-install
git clone git@github.com:GoogleCloudPlatform/platform-engineering.git
```

### Build the plugin

```bash
cd ./platform-engineering/google-cloud-backstage-plugins/cloudworkstations
yarn install
yarn clean
yarn tsc
yarn build
rm -rf node_modules (avoid overriding the peer deps)
```

### Go to the backstage app local directory and install the plugin

```bash
cd ../../backstage
cd packages/app
yarn add file://[path-to-backstage-local-plugins-directory]/cloudworkstations
```

### Grant the necessary Google Cloud IAM roles having the necessary permissions for CloudWorkstations

- workstations.workstations.list
- workstations.workstations.get
- workstations.workstations.start
- workstations.workstations.stop
- workstations.workstations.use (launch and use workstations within the plugin)
- workstations.workstations.delete

### Set up Google OAuth Backstage authentication

The plugin authenticates with Google Cloud through [Backstage Google Authentication Provider](https://backstage.io/docs/auth/google/provider).

After adding the necessary config for Google Auth given in the link above. Add the 
`plugin-auth-backend-module-google-provider` to the backend module.

To install the backend module: `yarn add @backstage/plugin-auth-backend-module-google-provider` in `./packages/backend`
and add the following to the `backend/src/index.ts`

```diff
   backend.add(import('@backstage/plugin-search-backend/alpha'));
   backend.add(import('@backstage/plugin-search-backend-module-catalog/alpha'));
   backend.add(import('@backstage/plugin-search-backend-module-techdocs/alpha'));

+  backend.add(import('@backstage/plugin-auth-backend-module-google-provider'));
```



### Add annotation to your component-info.yaml file.

Any component, that you would like the cloud workstations be related to, should include the following [GCP workstation config](https://cloud.google.com/workstations/docs/quickstart-set-up-workstations-console) annotation (replace placeholders with valid information):

```diff
// component-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: backstage
  description: Backstage application.
+  annotations:
+    google.com/cloudworkstations-config: projects/$PROJECT/locations/$REGION/workstationClusters/$WORKSTATION-CLUSTER/workstationConfigs/$WORKSTATION-CONFIG
spec:
  type: website
  lifecycle: development
```

Annotation value should consist of: Google Cloud project id, Google Cloud project zone, Google Cloud workstations cluster name and Google Cloud workstations config name.

### Modify EntityPage.tsx

packages/app/src/components/catalog/EntityPage.tsx

#### Add the Plugin import to the list of imports

```diff
// packages/app/src/components/catalog/EntityPage.tsx
import { TechDocsAddons } from '@backstage/plugin-techdocs-react';

import { ReportIssue } from '@backstage/plugin-techdocs-module-addons-contrib';

+import { WorkstationsCard } from '@googlecloud-backstage-plugins/cloudworkstations';
+import { isGCPCloudWorkstationsAvailable } from '@googlecloud-backstage-plugins/cloudworkstations';
+import { GcpCloudworkstationsPage } from '@googlecloud-backstage-plugins/cloudworkstations';
```

#### In your `overviewContent` constant, add the following switch case:

```diff
// packages/app/src/components/catalog/EntityPage.tsx
const overviewContent = (
  <Grid container spacing={3} alignItems="stretch">
    {entityWarningContent}
+
+   <EntitySwitch>
+     <EntitySwitch.Case if={isGCPCloudWorkstationsAvailable}>
+       <Grid item md={6} xs={12}>
+         <WorkstationsCard />
+       </Grid>
+     </EntitySwitch.Case>
+   </EntitySwitch>
```

#### or

#### For a routable tab section on the entity page. Depending on the entity spec type add in your `serviceEntityPage` or `websiteEntityPage` or `defaultEntityPage` the following entity layout route:

```diff
// packages/app/src/components/catalog/EntityPage.tsx
const serviceEntityPage = (
     <EntityLayout.Route path="/kubernetes" title="Kubernetes">
      <EntityKubernetesContent />
    </EntityLayout.Route>

+    <EntityLayout.Route
+      path="/gcp-cloudworkstations"
+      title="GCP CloudWorkstations"
+    >
+      <GcpCloudworkstationsPage />
+    </EntityLayout.Route>
)
```
