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

import {GoogleAuth} from 'google-auth-library';
import {config} from './config';

async function testDeployCall() {
  try {
    // Configuration
    const projectId = config.project.id;
    const region = config.project.region;
    const deploymentId = `test-${Date.now()}-${Math.random().toString(36).substring(2, 10)}`;
    const bucketName = config.storage.terraformBucketName;
    const gcsPath = `gs://${bucketName}/${config.storage.catalogPath}/${config.templates['basic-vm'].path}`;
    const serviceAccountEmail = config.serviceAccount.email;
    const serviceAccount = `projects/${projectId}/serviceAccounts/${serviceAccountEmail}`;

    // Get authenticated client
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    const client = await auth.getClient();

    // Prepare the deployment request
    const payload = {
      terraform_blueprint: {
        gcs_source: gcsPath,
        input_values: {
          project_id: {
            input_value: projectId,
          },
          region: {
            input_value: region,
          },
        },
      },
      service_account: serviceAccount,
      labels: {
        environment: 'development',
        created_by: 'test',
      },
    };

    console.log(
      '🚀 Making deployment request with payload:',
      JSON.stringify(payload, null, 2)
    );

    // Make the API request
    const apiUrl = `https://config.googleapis.com/v1/projects/${projectId}/locations/${region}/deployments?deploymentId=${deploymentId}`;
    const response = await client.request({
      url: apiUrl,
      method: 'POST',
      data: payload,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-User-Project': projectId,
      },
    });

    console.log('✅ Response:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Run the test
testDeployCall().catch(console.error);
