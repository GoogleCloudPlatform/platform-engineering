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

# Use the official Node.js image
FROM node:22-slim

# Create app directory
WORKDIR /usr/src/app

# Copy source code
COPY . .

# Install dependencies, build and remove dev dependencies
RUN npm install && npm run build && npm prune --production

# Expose port
EXPOSE 8080

# Start the server
CMD [ "npm", "start" ]
