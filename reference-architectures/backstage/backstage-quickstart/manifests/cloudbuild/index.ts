/*
 * Hi!
 *
 * Note that this is an EXAMPLE Backstage backend. Please check the README.
 *
 * Happy hacking!
 */

import {createBackend} from '@backstage/backend-defaults';

//Custom auth resolver
import {createBackendModule} from '@backstage/backend-plugin-api';
import {gcpIapAuthenticator} from '@backstage/plugin-auth-backend-module-gcp-iap-provider';
import {
  authProvidersExtensionPoint,
  createProxyAuthProviderFactory,
} from '@backstage/plugin-auth-node';

import {stringifyEntityRef} from '@backstage/catalog-model';

const backend = createBackend();

backend.add(import('@backstage/plugin-app-backend'));
backend.add(import('@backstage/plugin-proxy-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));
backend.add(import('@backstage/plugin-techdocs-backend'));

// auth plugin
backend.add(import('@backstage/plugin-auth-backend'));
// See https://backstage.io/docs/backend-system/building-backends/migrating#the-auth-plugin
// backend.add(import('@backstage/plugin-auth-backend-module-guest-provider'));
// See https://backstage.io/docs/auth/guest/provider

// catalog plugin
backend.add(import('@backstage/plugin-catalog-backend'));
backend.add(
  import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model')
);

// See https://backstage.io/docs/features/software-catalog/configuration#subscribing-to-catalog-errors
backend.add(import('@backstage/plugin-catalog-backend-module-logs'));

// permission plugin
backend.add(import('@backstage/plugin-permission-backend'));
// See https://backstage.io/docs/permissions/getting-started for how to create your own permission policy
backend.add(
  import('@backstage/plugin-permission-backend-module-allow-all-policy')
);

// search plugin
backend.add(import('@backstage/plugin-search-backend'));

// search engine
// See https://backstage.io/docs/features/search/search-engines
backend.add(import('@backstage/plugin-search-backend-module-pg'));

// search collators
backend.add(import('@backstage/plugin-search-backend-module-catalog'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs'));

// kubernetes
backend.add(import('@backstage/plugin-kubernetes-backend'));

//Add custom resolver for IAP
const customAuthResolver = createBackendModule({
  pluginId: 'auth',
  moduleId: 'custom-auth-provider',
  register(reg) {
    reg.registerInit({
      deps: {providers: authProvidersExtensionPoint},
      async init({providers}) {
        providers.registerProvider({
          providerId: 'gcpIap',
          factory: createProxyAuthProviderFactory({
            authenticator: gcpIapAuthenticator,
            async signInResolver(info, ctx) {
              console.log(info);
              //const { profile: { email } } = info;
              const {
                result: {
                  iapToken: {email},
                },
              } = info;
              console.log(email);
              const userEntity = stringifyEntityRef({
                kind: 'User',
                //name: userId,
                name: email,
                namespace: 'default',
              });
              return ctx.issueToken({
                claims: {
                  sub: userEntity,
                  ent: [userEntity],
                },
              });
            },
          }),
        });
      },
    });
  },
});
backend.add(customAuthResolver);
backend.start();
