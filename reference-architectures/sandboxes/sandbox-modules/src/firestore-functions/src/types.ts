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

export interface Deployment {
  _updateSource: string;
  status: string;
  projectId: string;
  templateName: string;
  deploymentState: DeploymentState;
  infraManagerDeploymentId: string;
  userId: string;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  variables: DeploymentVariables;
  auditLog: string[];
}

export interface DeploymentState {
  budgetLimit: number;
  currentSpend: number;
  expiresAt: FirebaseFirestore.Timestamp;
}

export interface DeploymentVariables {
  billing_account: string;
  new_project_id: string;
  new_project_name: string;
  region: string;
}
