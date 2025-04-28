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
import { OperationResponse } from './types';

const firestore = new Firestore();
const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform']
});

export async function pollDeletionStatus(operationName: string, documentId: string, docRef: FirebaseFirestore.DocumentReference) {
    let retryCount = 0;
    const maxRetries = 10;
    const retryDelay = 5000;
  
    // Get authenticated client
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform']
    });
    const client = await auth.getClient();
  
    while (retryCount < maxRetries) {
      await new Promise(resolve => setTimeout(resolve, retryDelay));
  
      try {
        const operationResponse = await client.request<OperationResponse>({
          url: `https://config.googleapis.com/v1/${operationName}`,
          method: 'GET',
          headers: {
            'X-Goog-User-Project': config.project.id
          }
        });
  
        if (operationResponse.data.done) {
          if (operationResponse.data.error) {
            console.error(`[CloudRun] ❌ Deletion failed:`, {
              documentId,
              error: operationResponse.data.error
            });
  
            await docRef.update({
              status: 'delete_error',
              error: operationResponse.data.error,
              updatedAt: new Date(),
              _updateSource: 'cloudrun'
            });
  
            return;
          }
  
          console.log(`[CloudRun] ✅ Deletion completed successfully:`, {
            documentId,
            result: operationResponse.data.response
          });

          return;
        }
  
        // Update status to show progress
        await docRef.update({
          status: 'delete_inprogress',
          updatedAt: new Date(),
          _updateSource: 'cloudrun'
        });
  
      } catch (error) {
        console.warn(`[CloudRun] ⚠️ Error checking operation status (will retry):`, {
          documentId,
          error: error instanceof Error ? error.message : 'Unknown error',
          retry: retryCount + 1
        });
      }
  
      retryCount++;
    }
  
    // If we get here, polling timed out
    await docRef.update({
      status: 'delete_error',
      message: 'Deletion status check timed out, but deletion may still be in progress',
      updatedAt: new Date(),
      _updateSource: 'cloudrun'
    });
  }