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

import {
  // onDocumentWritten,
  onDocumentCreated,
  onDocumentUpdated,
  // onDocumentDeleted,
  // Change,
  // FirestoreEvent
} from "firebase-functions/v2/firestore";
import * as admin from 'firebase-admin';
import { Deployment,  } from "./types";
import { getAuthToken } from './auth';

// Initialize Firebase Admin
admin.initializeApp();

exports.deploymentCreated = onDocumentCreated("deployments/{deploymentId}", async (event) => {
  if (!event.data) {
    console.error('No data associated with the event');
    return;
  }

  const deploymentId = event.params.deploymentId;
  const data = event.data.data() as Deployment;

  console.log('[FirestoreTrigger] 📝 New deployment created:', deploymentId, { deploymentId });
  console.log('[FirestoreTrigger] 📋 Document data:', data, { deploymentId });

  // Skip processing if this update came from Cloud Run
  if (data._updateSource === 'cloudrun') {
    console.log('[FirestoreTrigger] ⏩ Skipping processing for Cloud Run update', { deploymentId });
    return null;
  }

  try {
    const templateName = data.templateName;
    if (!templateName) {
      console.log('[FirestoreTrigger] ⚠️ No deployment template name found, skipping', { deploymentId });
      return null;
    }

    // Get auth token for Cloud Run
    console.log('[FirestoreTrigger] 🔑 Getting auth token...', { deploymentId });
    const token = await getAuthToken();

    // Get Cloud Run URL from environment variable
    const cloudRunUrl = process.env.CLOUD_RUN_URL + "/create";
    if (!cloudRunUrl) {
      console.error('[FirestoreTrigger] 🚫 Cloud Run URL is not configured. Please set CLOUD_RUN_URL environment variable', { deploymentId });
      throw new Error('Cloud Run URL is not configured');
    }

    console.log('[FirestoreTrigger] 🚀 Calling Cloud Run service:', cloudRunUrl, { deploymentId });

    const response = await fetch(cloudRunUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        documentId: deploymentId,
        data: {
          name: templateName,
          type: templateName,
          region: 'us-central1'
        }
      })
    });

    if (!response.ok) {
      throw new Error(`Cloud Run service error: ${response.statusText}`);
    }

    const result = await response.json();
    console.log('[FirestoreTrigger] ✅ Deployment initiated successfully:', {
      deploymentId,
      templateName: templateName,
      result
    });

    return result;
  } catch (error) {
    console.error('[FirestoreTrigger] 🔥 Error processing deployment:', error, { deploymentId });
    throw error;
  }

  return null;
})

exports.deploymentUpdated = onDocumentUpdated("deployments/{deploymentId}", async (event) => {
  if (!event.data) {
    console.error('No data associated with the event');
    return;
  }

  const beforeData = event.data.before.data() as Deployment | undefined;
  const afterData = event.data.after.data() as Deployment | undefined;
  const deploymentId = event.params.deploymentId;

  // Validate data exists
  if (!beforeData || !afterData) {
    console.error('Missing before or after data');
    return;
  }

  try {
  // If the status field wasn't not delete and it now is, a new delete request
  // has been made. We need to call infra-manager-processor to have the
  // sandbox deleted.
  if (afterData.status == "delete_requested" && beforeData.status != "delete_requested") {
      // Get auth token for Cloud Run
      console.log('[FirestoreTrigger] 🔑 Getting auth token...', { deploymentId });
      const token = await getAuthToken();

      // Get Cloud Run URL from environment variable
      const cloudRunUrl = process.env.CLOUD_RUN_URL + "/delete";
      if (!cloudRunUrl) {
        console.error('[FirestoreTrigger] 🚫 Cloud Run URL is not configured. Please set CLOUD_RUN_URL environment variable', { deploymentId });
        throw new Error('Cloud Run URL is not configured');
      }

      console.log('[FirestoreTrigger] 🚀 Calling Cloud Run service:', cloudRunUrl, { deploymentId });
  
      const response = await fetch(cloudRunUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          documentId: deploymentId,
          data: {
            infraManagerDeploymentId: afterData.infraManagerDeploymentId,
            region: 'us-central1'
          }
        })
      });

      if (!response.ok) {
        throw new Error(`Cloud Run service error: ${response.statusText}`);
      }

      const result = await response.json();
      console.log('[FirestoreTrigger] ✅ Delete initiated successfully:', {
        deploymentId,
        result
      });

      return result;
  }
  } catch (error) {
    console.error('[FirestoreTrigger] 🔥 Error processing deployment:', error, { deploymentId });
    throw error;
  }
});
