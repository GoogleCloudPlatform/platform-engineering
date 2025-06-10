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

export interface Config {
  project: {
    id: string;
    region: string;
  };
  storage: {
    terraformBucketName: string;
    terraformStateBucketName: string;
    catalogPath: string;
  };
  serviceAccount: {
    name: string;
    email: string;
  };
  terraform: {
    version: string;
    files: string[];
  };
  service: {
    port: number | string;
    url: string;
  };
  // Make templates a dynamic record with string keys
  templates: Record<string, Template>;
}

export interface DeleteRequest {
  documentId: string;
  data: {
    infraManagerDeploymentId: string;
    region: string;
  };
}

export interface DeploymentResponse {
  name: string;
  status: number;
}

export interface DeploymentRequest {
  documentId: string;
  data: {
    name: string; // Deployment name
    region: string; // Deployment region
    type: TemplateType; // Type of infrastructure (e.g., 'basic-vm', 'gke-basic')
  };
}

export interface OperationResponse {
  name: string;
  done: boolean;
  error?: any /* eslint-disable-line @typescript-eslint/no-explicit-any */;
  response?: any /* eslint-disable-line @typescript-eslint/no-explicit-any */;
}

export interface Template {
  path: string;
  description: string;
  requiredVariables: string[];
}

// Make template type a string to allow for dynamic types
export type TemplateType = string;
