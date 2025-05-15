#!/usr/bin/env bash
#
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

SCRIPT_BASENAME="$(basename "${0}")"
SCRIPT_DIRECTORY_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

echo "This script (${SCRIPT_BASENAME}) has been invoked with: $0 $*"
echo "This script directory path is: ${SCRIPT_DIRECTORY_PATH}"

# shellcheck disable=SC1091
. "${SCRIPT_DIRECTORY_PATH}/common.sh"

TERRAFORM_DIRECTORY_PATH="${SCRIPT_DIRECTORY_PATH}/terraform"

start_timestamp=$(date +%s)

# shellcheck disable=SC2154
echo "Core platform terraservices to destroy: ${terraservices[*]}"

# shellcheck disable=SC1091
. "${SCRIPT_DIRECTORY_PATH}/load-shared-config.sh" "${TERRAFORM_DIRECTORY_PATH}/_shared_config"

# Iterate over the terraservices array so we destroy them in reverse order
# shellcheck disable=SC2154 # variable defined in common.sh
for ((i = ${#terraservices[@]} - 1; i >= 0; i--)); do
  terraservice=${terraservices[i]}
  echo "Destroying ${terraservice}"
  if [[ "${terraservice}" != "initialize" ]]; then
    terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/${terraservice}" init
    terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/${terraservice}" destroy -auto-approve
    rm -rf .terraform/
  # Destroy the backend only if we're destroying the initialize service
  else
    rm -rf "${TERRAFORM_DIRECTORY_PATH}/${terraservice}/backend.tf"
    terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/${terraservice}" init -force-copy -lock=false -migrate-state

    # Quote the globbing expression because we don't want to expand it with the
    # shell
    gcloud storage rm -r "gs://${terraform_bucket_name}/*"
    terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/${terraservice}" destroy -auto-approve

    rm -rf \
      "${TERRAFORM_DIRECTORY_PATH}/_shared_config/.terraform/" \
      "${TERRAFORM_DIRECTORY_PATH}/_shared_config"/terraform.tfstate* \
      "${TERRAFORM_DIRECTORY_PATH}/initialize/.terraform/" \
      "${TERRAFORM_DIRECTORY_PATH}/initialize"/terraform.tfstate*

    git restore \
      "${TERRAFORM_DIRECTORY_PATH}/_shared_config"/*.auto.tfvars
  fi
done

end_timestamp=$(date +%s)
total_runtime_value=$((end_timestamp - start_timestamp))
echo "Total runtime: $(date -d@${total_runtime_value} -u +%H:%M:%S)"
