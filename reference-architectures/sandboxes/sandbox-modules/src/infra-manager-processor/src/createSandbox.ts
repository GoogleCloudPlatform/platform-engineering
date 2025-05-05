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

import { GoogleAuth } from 'google-auth-library';
import { Firestore } from '@google-cloud/firestore';
import { config } from './config';
import { DeploymentResponse, OperationResponse, TemplateType } from './types';

const firestore = new Firestore();
const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform']
});

// Real function to deploy infrastructure using Infrastructure Manager API
export async function deployInfrastructure(documentId: string, templateType: TemplateType, region: string) {
    console.log(`[InfraManager] 🚀 Starting deployment process for document ${documentId}`, {
      documentId,
      templateType,
      region,
      timestamp: new Date().toISOString()
    });

    const docRef = firestore.collection('deployments').doc(documentId);

    try {
      // Keep document in pending status but add message noting that the request is being prepared
      await docRef.update({
        updatedAt: new Date(),
        _updateSource: 'cloudrun',
        message: 'Preparing deployment request'
      });

      // Get the document data for variables
      const docSnapshot = await docRef.get();
      const docData = docSnapshot.data();
      if (!docData) {
        throw new Error('Document data not found');
      }

      // Generate a unique deployment ID for Infrastructure Manager
      const deploymentId = `deploy-${Date.now()}-${Math.random().toString(36).substring(2, 10)}`;

      // Determine the template path based on type
      const bucketName = config.storage.terraformBucketName;
      const catalogPath = config.storage.catalogPath;
      const gcsPath = `gs://${bucketName}/${catalogPath}/${templateType}`;
      const gcsStatePath = `gs://${config.storage.terraformStateBucketName}`;
      // Construct the full service account resource name
      const serviceAccount = `projects/${config.project.id}/serviceAccounts/${config.serviceAccount.email}`;

      // Prepare input values for Terraform
      const inputValues: Record<string, { inputValue: string }> = {};

      try {
        // Add all variables from the document
        if (docData?.variables) {
          Object.entries(docData.variables).forEach(([key, value]) => {
            inputValues[key] = { inputValue: value as string };
          });
        }

        // Add default variables if not provided
        if (!inputValues.project_id) {
          inputValues.project_id = { inputValue: config.project.id };
        }
        if (!inputValues.region) {
          inputValues.region = { inputValue: region };
        }
        if (!inputValues.zone && templateType !== 'project') {
          inputValues.zone = { inputValue: config.project.zone };
        }
      } catch (error) {
        console.error(`[InfraManager] ❌ Error preparing variables:`, {
          documentId,
          error: error instanceof Error ? error.message : 'Unknown error',
          docData
        });
        throw new Error('Failed to prepare deployment variables');
      }

      // Prepare the deployment request
      const payload = {
        terraform_blueprint: {
          gcs_source: gcsPath,
          input_values: inputValues
        },
        service_account: serviceAccount,
        labels: {
          environment: (process.env.NODE_ENV || 'development').toLowerCase(),
          created_by: 'cloudrun',
          template_type: templateType,
          doc_id: documentId.toLowerCase().replace(/[^a-z0-9-]/g, '-')
        }
      };

      // Get authenticated client for Infrastructure Manager API
      const auth = new GoogleAuth({
        scopes: ['https://www.googleapis.com/auth/cloud-platform']
      });
      const client = await auth.getClient();

      // Update status with more detail before API call
      await docRef.update({
        message: 'Submitting deployment to Infrastructure Manager',
        updatedAt: new Date(),
        _updateSource: 'cloudrun'
      });

      // Make the API request to Infrastructure Manager
      const apiUrl = `https://config.googleapis.com/v1/projects/${config.project.id}/locations/${region}/deployments?deploymentId=${deploymentId}`;

      console.log(`[InfraManager] 🚀 Sending request to Infrastructure Manager API:`, {
        documentId,
        deploymentId,
        url: apiUrl,
        payload: JSON.stringify(payload, null, 2)
      });

      const response = await client.request<DeploymentResponse>({
        url: apiUrl,
        method: 'POST',
        data: payload,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-User-Project': config.project.id
        }
      });

      // Store operation details
      await docRef.update({
        operationName: response.data.name,
        infraManagerDeploymentId: deploymentId,
        updatedAt: new Date(),
        _updateSource: 'cloudrun',
        message: 'Deployment submitted successfully, starting status checks',
        consoleUrl: `https://console.cloud.google.com/config-management/deployments/detail/${region}/${deploymentId}?project=${config.project.id}`
      });

      // Poll for deployment status
      let deploymentComplete = false;
      let retryCount = 0;
      const maxRetries = 30;
      const retryDelay = 10000;

      while (!deploymentComplete && retryCount < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, retryDelay));

        try {
          const operationResponse = await client.request<OperationResponse>({
            url: `https://config.googleapis.com/v1/${response.data.name}`,
            method: 'GET',
            headers: {
              'X-Goog-User-Project': config.project.id
            }
          });

          console.log(`[InfraManager] 🔄 Checking operation status:`, {
            documentId,
            operationStatus: operationResponse.data.done ? 'complete' : 'in progress',
            attempt: `${retryCount + 1}/${maxRetries}`
          });

          // Update status to in progress on each poll if not done
          if (!operationResponse.data.done) {
            await docRef.update({
              status: 'provision_inprogress',
              updatedAt: new Date(),
              _updateSource: 'cloudrun',
              message: `Deployment in progress (check ${retryCount + 1}/${maxRetries})`,
              operationStatus: 'in progress',
              attempt: `${retryCount + 1}/${maxRetries}`
            });
          }

          if (operationResponse.data.done) {
            deploymentComplete = true;

            if (operationResponse.data.error) {
              // Deployment failed
              console.error(`[InfraManager] ❌ Deployment failed:`, {
                documentId,
                error: operationResponse.data.error
              });

              await docRef.update({
                status: 'provision_error',
                error: operationResponse.data.error,
                updatedAt: new Date(),
                _updateSource: 'cloudrun'
              });

              return {
                status: 'provision_error',
                documentId,
                error: operationResponse.data.error
              };
            }

            // Deployment succeeded
            console.log(`[InfraManager] ✅ Deployment completed successfully:`, {
              documentId,
              infraManagerResult: operationResponse.data.response
            });

            await docRef.update({
              status: 'provision_successful',
              infraManagerResult: operationResponse.data.response,
              updatedAt: new Date(),
              _updateSource: 'cloudrun',
              consoleUrl: `https://console.cloud.google.com/config-management/deployments/detail/${region}/${deploymentId}?project=${config.project.id}`
            });

            return {
              status: 'success',
              documentId,
              infraManagerResult: operationResponse.data.response
            };
          }
        } catch (error) {
          console.warn(`[InfraManager] ⚠️ Error checking operation status (will retry):`, {
            documentId,
            error: error instanceof Error ? error.message : 'Unknown error',
            retry: retryCount + 1
          });
        }

        retryCount++;
      }

      if (!deploymentComplete) {
        console.log(`[InfraManager] ⏱️ Deployment status check timeout reached, continuing in background:`, {
          documentId
        });

        await docRef.update({
          status: 'provision_inprogress',
          message: 'Deployment continuing in background. Check console for latest status.',
          updatedAt: new Date(),
          _updateSource: 'cloudrun',
          consoleUrl: `https://console.cloud.google.com/config-management/deployments/detail/${region}/${deploymentId}?project=${config.project.id}`
        });

        return {
          status: 'provision_inprogress',
          documentId,
          message: 'Deployment continuing in background. Check console for latest status.'
        };
      }

      return { status: 'success', documentId };
    } catch (error) {
      console.error(`[InfraManager] ❌ Error creating deployment:`, {
        documentId,
        error: error instanceof Error ? error.message : 'Unknown error'
      });

      await docRef.update({
        status: 'failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        updatedAt: new Date(),
        _updateSource: 'cloudrun'
      });

      throw error;
    }
  }
  