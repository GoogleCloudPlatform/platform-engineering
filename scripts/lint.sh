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

#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# shellcheck disable=SC1091,SC1094
. ./scripts/common.sh

echo "Running lint checks"

LINT_CI_JOB_PATH=".github/workflows/linters.yaml"
DEFAULT_LINTER_CONTAINER_IMAGE_VERSION="$(grep <"${LINT_CI_JOB_PATH}" "super-linter/super-linter" | awk -F '@' '{print $2}' | head --lines=1)"

LINTER_CONTAINER_IMAGE="ghcr.io/super-linter/super-linter:${LINTER_CONTAINER_IMAGE_VERSION:-${DEFAULT_LINTER_CONTAINER_IMAGE_VERSION}}"

echo "Running linter container image: ${LINTER_CONTAINER_IMAGE}"

SUPER_LINTER_COMMAND=(
  docker run
)

if [ -t 0 ]; then
  SUPER_LINTER_COMMAND+=(
    --interactive
    --tty
  )
fi

if [ "${LINTER_CONTAINER_OPEN_SHELL:-}" == "true" ]; then
  SUPER_LINTER_COMMAND+=(
    --entrypoint "/bin/bash"
  )
fi

SUPER_LINTER_COMMAND+=(
  --env-file "config/lint/super-linter.env"
)

if [ "${LINTER_CONTAINER_FIX_MODE:-}" == "true" ]; then
  SUPER_LINTER_COMMAND+=(
    --env-file "config/lint/super-linter-fix-mode.env"
  )
fi

if is_linter_config_changed; then
  echo "Configure Super-linter to validate the entire codebase"
  SUPER_LINTER_COMMAND+=(--env VALIDATE_ALL_CODEBASE="true")
fi

SUPER_LINTER_COMMAND+=(
  --env CREATE_LOG_FILE="true"
  --env LOG_LEVEL="${LOG_LEVEL:-"INFO"}"
  --env MULTI_STATUS="false"
  --env REMOVE_ANSI_COLOR_CODES_FROM_OUTPUT="true"
  --env RUN_LOCAL="true"
  --env SAVE_SUPER_LINTER_OUTPUT="true"
  --name "super-linter"
  --rm
  --volume "$(pwd)":/tmp/lint
  --volume /etc/localtime:/etc/localtime:ro
  --workdir /tmp/lint
  "${LINTER_CONTAINER_IMAGE}"
  "$@"
)

echo "Super-linter command: ${SUPER_LINTER_COMMAND[*]}"
"${SUPER_LINTER_COMMAND[@]}"
