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
source "${SCRIPT_DIRECTORY_PATH}/common.sh"

start_timestamp=$(date +%s)

# shellcheck disable=SC2154
echo "Terraservices to provision: ${terraservices[*]}"

TERRAFORM_DIRECTORY_PATH="${SCRIPT_DIRECTORY_PATH}/terraform"

terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/initialize" init -force-copy -migrate-state &&
  terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/initialize" plan -input=false -out=tfplan &&
  terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/initialize" apply -input=false tfplan

# Run init again in case we migrated the state
terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/initialize" init -force-copy -migrate-state &&
  terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/initialize" plan -input=false -out=tfplan &&
  terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/initialize" apply -input=false tfplan

rm -rf "${TERRAFORM_DIRECTORY_PATH}/initialize/terraform.tfstate"*
rm -rf "${TERRAFORM_DIRECTORY_PATH}/initialize/tfplan"

for terraservice in "${terraservices[@]}"; do
  terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/${terraservice}" init &&
    terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/${terraservice}" plan -input=false -out=tfplan &&
    terraform -chdir="${TERRAFORM_DIRECTORY_PATH}/${terraservice}" apply -input=false tfplan || exit 1
  rm -rf "${TERRAFORM_DIRECTORY_PATH}/${terraservice}/tfplan"
done

end_timestamp=$(date +%s)
total_runtime_value=$((end_timestamp - start_timestamp))
echo "Total runtime: $(date -d@${total_runtime_value} -u +%H:%M:%S)"
