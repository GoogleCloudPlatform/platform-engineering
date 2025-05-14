/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* eslint-disable n/no-missing-import */

import {Config} from './types';

// Validate required environment variables
const requiredEnvVars = ['PROJECT_ID', 'REGION', 'ZONE'] as const;
for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`${envVar} environment variable is required but not set`);
  }
}

// After validation, we know these exist
const PROJECT_ID = process.env.PROJECT_ID!;
const REGION = process.env.REGION!;
const ZONE = process.env.ZONE!;

export const config: Config = {
  project: {
    id: PROJECT_ID,
    region: REGION,
    zone: ZONE,
  },
  storage: {
    get terraformBucketName() {
      return process.env.TERRAFORM_BUCKET || `${config.project.id}-catalog`;
    },
    get terraformStateBucketName() {
      return process.env.TERRAFORM_STATE_BUCKET || `${config.project.id}-state`;
    },
    catalogPath: process.env.TERRAFORM_CATALOG_PATH || 'templates',
  },
  serviceAccount: {
    name: process.env.SERVICE_ACCOUNT_NAME || 'inframgr-sa',
    get email() {
      return `${this.name}@${config.project.id}.iam.gserviceaccount.com`;
    },
  },
  terraform: {
    version: '1.5.7',
    files: ['main.tf', 'variables.tf', 'outputs.tf'],
  },
  service: {
    port: process.env.PORT || 8080,
    url: process.env.SERVICE_URL || 'http://localhost:8080',
  },
  templates: {}, // Will be populated dynamically
};
