#!/usr/bin/env bash

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

set -o errexit
set -o nounset
set -o pipefail

# renovate: datasource=docker packageName=squidfunk/mkdocs-material versioning=docker
MKDOCS_CONTAINER_IMAGE_VERSION="9.5.50"
MKDOCS_CONTAINER_IMAGE="squidfunk/mkdocs-material:${MKDOCS_CONTAINER_IMAGE_VERSION}"

# Set up a tempdir and files, deleted on exit if required
TEMP_DIR="$(mktemp --directory)"
export TEMP_DIR
on_exit() {
  if [[ "${KEEP_TEMP_FILES:-}" == "true" ]]; then
    echo "Output files stored in ${TEMP_DIR}"
  else
    echo "Deleting ${TEMP_DIR}. Set KEEP_TEMP_FILES=true to avoid deleting this directory."
    rm -fr "${TEMP_DIR}"
  fi
}
trap on_exit EXIT
