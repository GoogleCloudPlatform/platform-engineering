# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
apiVersion: v1
kind: Namespace
metadata:
  name: app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
    color: blue #from-param: ${color}
  namespace: app
spec:
  replicas: 1 #from-param: ${replicaCount}
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: us-docker.pkg.dev/${PROJECT_ID}/my-repo/app:latest
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 250m
            memory: 512Mi
          requests:
            cpu: 250m
            memory: 512Mi
---
kind: Service
apiVersion: v1
metadata:
  name: myapp
  namespace: app
  labels:
    color: blue #from-param: ${color}
spec:
  selector:
    app: myapp
  ports:
  - port: 8080
    targetPort: 8080