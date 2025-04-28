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

import express from 'express';
import { Firestore } from '@google-cloud/firestore';
import { Storage } from '@google-cloud/storage';
import { GoogleAuth } from 'google-auth-library';
import { config } from './config';
import { DeleteRequest, DeploymentRequest, OperationResponse } from './types';
import { deployInfrastructure } from './createSandbox';
import { pollDeletionStatus } from './deleteSandbox';

const app = express();
const firestore = new Firestore();
const storage = new Storage();
const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform']
});
const port = process.env.PORT || 8080;

// Track whether templates have been loaded
let templatesLoaded = false;
let templateLoadError: Error | null = null;

// Load templates before starting server
async function initializeTemplates() {
  try {
    const bucketName = config.storage.terraformBucketName;
    const templates: Record<string, any> = {};

    // List all template directories in both deployments and projects
    const [deploymentFiles] = await storage.bucket(bucketName).getFiles({
      prefix: 'catalog/'
    });

    // Process deployment templates
    for (const file of deploymentFiles) {
      if (file.name.endsWith('metadata.json')) {
        const templateName = file.name.split('/')[2]; // Get directory name
        const content = await file.download();
        const metadata = JSON.parse(content[0].toString());
        templates[templateName] = {
          path: templateName,
          description: metadata.description,
          requiredVariables: metadata.variables
            ?.filter((v: any) => v.required)
            .map((v: any) => v.name) || []
        };
      }
    }

    // Update config templates
    Object.assign(config.templates, templates);
    templatesLoaded = true;
    console.log('📚 Loaded templates:', Object.keys(templates));
  } catch (error) {
    templateLoadError = error as Error;
    console.error('❌ Failed to load templates:', error);
    // Load default templates as fallback
    Object.assign(config.templates, {
      'empty-project': {
        path: 'empty-project',
        description: 'Project creation template for an empty project',
        requiredVariables: ['name', 'billing_account', 'parent_folder']
      }
    });
    templatesLoaded = true;
  }
}

// Middleware to parse JSON bodies
app.use(express.json());

// Add request logging middleware
app.use((req, res, next) => {
  const requestId = `req-${Date.now()}-${Math.random().toString(36).substring(2, 10)}`;
  req.headers['x-request-id'] = requestId;
  
  // Extract documentId from request body for logging
  const documentId = req.body?.documentId || 'unknown';
  
  console.log(`[CloudRun][${requestId}] 📥 Received ${req.method} request to ${req.path}`, {
    deploymentId: documentId,
    headers: req.headers,
    query: req.query,
    body: req.body
  });
  
  // Capture response
  const originalSend = res.send;
  res.send = function(body) {
    console.log(`[CloudRun][${requestId}] 📤 Sending response with status ${res.statusCode}`, {
      deploymentId: documentId,
      body: typeof body === 'string' ? body : JSON.stringify(body)
    });
    return originalSend.call(this, body);
  };
  
  next();
});

// Add middleware to check if templates are loaded
app.use(async (req, res, next) => {
  if (!templatesLoaded) {
    try {
      await initializeTemplates();
    } catch (error) {
      console.error('Failed to initialize templates:', error);
      return res.status(500).json({ error: 'Service initialization failed' });
    }
  }
  next();
});

app.post('/create', async (req, res) => {
  const requestId = req.headers['x-request-id'] as string;
  const { documentId, data } = req.body as DeploymentRequest;
  
  try {
    console.log(`[CloudRun][${requestId}] 🔍 Processing deployment request`, { documentId });
    
    if (!documentId) {
      console.error(`[CloudRun][${requestId}] ❌ Missing documentId in request`, { documentId: 'unknown' });
      return res.status(400).json({ error: 'Missing documentId in request' });
    }
    
    if (!data || !data.type || !data.region) {
      console.error(`[CloudRun][${requestId}] ❌ Missing required data fields`, { documentId, data });
      return res.status(400).json({ error: 'Missing required data fields' });
    }
    
    // Get the document reference
    const docRef = firestore.collection('deployments').doc(documentId);
    const docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      console.error(`[CloudRun][${requestId}] ❌ Document does not exist: ${documentId}`);
      return res.status(404).json({ error: 'Deployment document not found' });
    }
    
    const currentData = docSnapshot.data();
    if (currentData?.status !== 'provision_requested') {
      console.error(`[CloudRun][${requestId}] ❌ Invalid deployment status: ${currentData?.status}`, { documentId });
      return res.status(400).json({ 
        error: 'Invalid deployment status',
        message: 'Deployment must be in "requested" status to proceed'
      });
    }
    
    // Update document to pending status
    await docRef.update({
      status: 'provision_pending',
      updatedAt: new Date(),
      _updateSource: 'cloudrun',
    });
    
    console.log(`[CloudRun][${requestId}] 📋 Document updated with pending status`, { documentId });
    
    // Start deployment process in background
    deployInfrastructure(documentId, data.type, data.region)
      .catch(error => {
        console.error(`[CloudRun][${requestId}] 🔥 Error in background deployment process:`, error, { documentId });
        docRef.update({
          status: 'provision_error',
          updatedAt: new Date(),
          _updateSource: 'cloudrun',
          error: error.message || 'Unknown error'
        }).catch(updateError => {
          console.error(`[CloudRun][${requestId}] 🚫 Failed to update document with error status:`, updateError, { documentId });
        });
      });
    
    // Respond immediately
    console.log(`[CloudRun][${requestId}] ✅ Sending success response`, { documentId });
    res.json({
      status: 'success',
      documentId,
      message: 'Deployment initiated'
    });
  } catch (error) {
    console.error(`[CloudRun][${requestId}] 🔥 Error processing request:`, error, { documentId });
    res.status(500).json({ 
      error: 'Failed to process request',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

app.post('/delete', async (req, res) => {
  const requestId = req.headers['x-request-id'] as string;
  const { documentId, data } = req.body as DeleteRequest;
  
  try {
    console.log(`[CloudRun][${requestId}] 🔍 Processing deletion request`, { documentId });
    
    if (!documentId) {
      console.error(`[CloudRun][${requestId}] ❌ Missing documentId in request`, { documentId: 'unknown' });
      return res.status(400).json({ error: 'Missing documentId in request' });
    }
    
    if (!data || !data.infraManagerDeploymentId || !data.region) {
      console.error(`[CloudRun][${requestId}] ❌ Missing required data fields`, { documentId, data });
      return res.status(400).json({ error: 'Missing required data fields' });
    }
    else
    {
      console.log(`[CloudRun][${requestId}] 🔍 Deletion request details`, { documentId, data })
    }

    // Get the document reference
    const docRef = firestore.collection('deployments').doc(documentId);
    const docSnapshot = await docRef.get();
    
    if (!docSnapshot.exists) {
      console.error(`[CloudRun][${requestId}] ❌ Document does not exist: ${documentId}`);
      return res.status(404).json({ error: 'Deployment document not found' });
    }

    // Get authenticated client for Infrastructure Manager API
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform']
    });
    const client = await auth.getClient();

    // Make the API request to Infrastructure Manager
    const apiUrl = `https://config.googleapis.com/v1/projects/${config.project.id}/locations/${data.region}/deployments/${data.infraManagerDeploymentId}?force=true`;
    
    console.log(`[CloudRun][${requestId}] 🚀 Sending delete request to Infrastructure Manager API:`, {
      documentId,
      infraManagerDeploymentId: data.infraManagerDeploymentId,
      url: apiUrl,
      force: true  // Log that we're using force delete
    });

    const response = await client.request<OperationResponse>({
      url: apiUrl,
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-User-Project': config.project.id
      }
    });

    // Log the operation details
    const operationId = response.data.name.split('/').pop();
    console.log(`[CloudRun][${requestId}] 📋 Deletion operation details:`, {
      documentId,
      operationId,
      operationName: response.data.name,
      consoleUrl: `https://console.cloud.google.com/config-management/operations/${operationId}?project=${config.project.id}`
    });

    // Update document with operation details
    await docRef.update({
      operationName: response.data.name,
      status: 'delete_pending',
      updatedAt: new Date(),
      _updateSource: 'cloudrun'
    });

    // Respond immediately
    console.log(`[CloudRun][${requestId}] ✅ Sending success response`, { documentId });
    res.json({
      status: 'success',
      documentId,
      message: 'Deletion initiated',
      operationName: response.data.name
    });

    // Start polling in background
    pollDeletionStatus(response.data.name, documentId, docRef)
      .catch(error => {
        console.error(`[CloudRun][${requestId}] 🔥 Error in background polling:`, error, { documentId });
        docRef.update({
          status: 'delete_error',
          updatedAt: new Date(),
          _updateSource: 'cloudrun',
          error: error.message || 'Unknown error'
        }).catch(updateError => {
          console.error(`[CloudRun][${requestId}] 🚫 Failed to update document with error status:`, updateError, { documentId });
        });
      });
  } catch (error) {
    console.error(`[CloudRun][${requestId}] 🔥 Error processing request:`, error, { documentId });
    res.status(500).json({ 
      error: 'Failed to process request',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Set up periodic check for delete requests
// setInterval(processDeleteRequests, 60000); // Check every minute

app.listen(port, () => {
  console.log(`[CloudRun] 🚀 Server listening on port ${port}`);
  console.log(`[CloudRun] 🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`[CloudRun] 📌 Project ID: ${config.project.id}`);
  console.log(`[CloudRun] 📍 Region: ${config.project.region}`);
});