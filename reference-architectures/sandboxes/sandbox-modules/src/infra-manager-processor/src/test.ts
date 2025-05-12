/**
 * Copyright 2024 Google LLC
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

// Quick test script
import {Firestore} from '@google-cloud/firestore';
import {Storage} from '@google-cloud/storage';
import {GoogleAuth} from 'google-auth-library';
import {config} from './config';
import {TemplateType} from './types';

/*
async function test() {
  console.log('Running test...');

  try {
    const firestore = new Firestore();
    const docRef = firestore.collection('test').doc('test-doc');

    await docRef.set({
      message: 'Hello from test script',
      timestamp: new Date()
    });

    console.log('Test document created successfully');
  } catch (error) {
    console.error('Test failed:', error);
  }
}

test();
*/

// Define interfaces for API responses
interface OperationResponse {
  name: string;
  done: boolean;
  error?: any;
  response?: any;
}

interface DeploymentResponse {
  name: string;
  status: number;
}

async function testInfraManagerDeploy() {
  console.log('🧪 Testing Infrastructure Manager deployment');
  console.log('📌 Project:', config.project.id);
  console.log('📍 Region:', config.project.region);

  try {
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    const client = await auth.getClient();

    // Setup deployment parameters
    const deploymentId = `test-deploy-${Date.now()}`;
    const templateType: TemplateType = 'basic-vm';
    const bucketName = config.storage.terraformBucketName;
    const templatePath = config.templates[templateType].path;
    const gcsPath = `gs://${bucketName}/${config.storage.catalogPath}/${templatePath}`;

    console.log('\n📋 Deployment configuration:');
    console.log(`- Project ID: ${config.project.id}`);
    console.log(`- Location: ${config.project.region}`);
    console.log(`- Deployment ID: ${deploymentId}`);
    console.log(`- Template: ${templateType}`);
    console.log(`- GCS Path: ${gcsPath}`);
    console.log(`- Service Account: ${config.serviceAccount.email}`);
    console.log(`- Terraform Version: ${config.terraform.version}`);

    // Prepare input values for Terraform
    const inputValues: Record<string, {inputValue: string}> = {
      project_id: {inputValue: config.project.id},
      region: {inputValue: config.project.region},
      zone: {inputValue: config.project.zone},
    };

    // Prepare the deployment request following Infrastructure Manager API spec
    const deploymentName = `projects/${config.project.id}/locations/${config.project.region}/deployments/${deploymentId}`;
    const serviceAccount = `projects/${config.project.id}/serviceAccounts/${config.serviceAccount.email}`;

    const payload = {
      name: deploymentName,
      terraformBlueprint: {
        gcsSource: gcsPath,
        inputValues: inputValues,
      },
      serviceAccount: serviceAccount,
      tfVersionConstraint: config.terraform.version,
      // Add quota validation as recommended in the docs
      quotaValidation: 'ENABLED',
      // Add labels and annotations as recommended in the docs
      labels: {
        environment: 'test',
        created_by: 'infrastructure-manager-test',
      },
      annotations: {
        description: 'Test deployment from Infrastructure Manager API',
        template_type: templateType,
      },
    };

    // Make the API request to Infrastructure Manager
    const apiUrl = `https://config.googleapis.com/v1/projects/${config.project.id}/locations/${config.project.region}/deployments?deploymentId=${deploymentId}`;
    console.log('\n🚀 Creating deployment using Infrastructure Manager API...');
    console.log('📝 API URL:', apiUrl);
    console.log('📦 Payload:', JSON.stringify(payload, null, 2));

    const response = await client.request<DeploymentResponse>({
      url: apiUrl,
      method: 'POST',
      data: payload,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-User-Project': config.project.id,
      },
    });

    console.log('\n✅ Deployment request accepted:', {
      status: response.status,
      operation: response.data.name,
    });

    // Poll for initial operation status
    console.log('\n🔄 Checking initial operation status...');
    const operationResponse = await client.request<OperationResponse>({
      url: `https://config.googleapis.com/v1/${response.data.name}`,
      method: 'GET',
      headers: {
        'X-Goog-User-Project': config.project.id,
      },
    });

    console.log('📊 Operation status:', {
      name: operationResponse.data.name,
      done: operationResponse.data.done,
      error: operationResponse.data.error || 'none',
    });

    // Print deployment URL
    console.log('\n🔍 View deployment in Console:');
    console.log(
      `https://console.cloud.google.com/config-management/deployments/detail/${config.project.region}/${deploymentId}?project=${config.project.id}`
    );

    // Print helpful next steps
    console.log('\n📋 Next steps:');
    console.log('1. View the deployment in the Console using the URL above');
    console.log('2. Monitor the deployment progress');
    console.log('3. Check quota usage if any warnings appear');
    console.log(
      `4. View deployed resources once complete in project: ${config.project.id}`
    );
  } catch (error) {
    console.error(
      '\n❌ Deployment failed:',
      error instanceof Error ? error.message : 'Unknown error'
    );
    if (error instanceof Error && error.stack) {
      console.error('Stack trace:', error.stack);
    }
    // Print troubleshooting tips based on the docs
    console.log('\n💡 Troubleshooting tips:');
    console.log('1. Verify service account permissions');
    console.log('2. Check if the GCS bucket and template files exist');
    console.log('3. Validate Terraform configuration syntax');
    console.log('4. Review quota limits for resources being deployed');
  }
}

// Run the focused test
testInfraManagerDeploy();
