# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
gcloud builds submit --config=cloudbuild.yaml --substitutions=_LOCATION=$LOCATION .

# Deploy the sample application, service and service export manifest to both clusters

gcloud container clusters get-credentials primary-cluster --zone=${ZONE_1} --project=$PROJECT_ID
gcloud container clusters get-credentials secondary-cluster --zone=${ZONE_2} --project=$PROJECT_ID

ls -l

kubectl apply  -k manifests/overlays/config-cluster --context gke_${PROJECT_ID}_${ZONE_1}_primary-cluster 
kubectl apply -k manifests/base --context gke_${PROJECT_ID}_${ZONE_2}_secondary-cluster 

export VIP=$(kubectl get gateways.gateway.networking.k8s.io app-gateway \
      -o=jsonpath="{.status.addresses[*].value}" \
      --context gke_${PROJECT_ID}_${ZONE_1}_primary-cluster \
      --namespace myapp)

echo http://$VIP
