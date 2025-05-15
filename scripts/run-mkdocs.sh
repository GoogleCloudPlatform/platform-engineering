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

PATH_TO_THIS_SCRIPT="${0}"
REPOSITORY_ROOT_DIRECTORY_PATH="$(readlink -f "$(dirname "${PATH_TO_THIS_SCRIPT}")/../")"
echo "Repository root directory path: ${REPOSITORY_ROOT_DIRECTORY_PATH}"

# shellcheck disable=SC1091 # do not follow
source "${REPOSITORY_ROOT_DIRECTORY_PATH}/scripts/common.sh" || exit 1

echo "Running mkdocs: ${MKDOCS_CONTAINER_IMAGE}"

SUBCOMMAND="${1:-"build"}"
echo "Subcommand: ${SUBCOMMAND}"

MKDOCS_CONFIG_DIRECTORY="${REPOSITORY_ROOT_DIRECTORY_PATH}/config/mkdocs"
MKDOCS_SOURCE_DIRECTORY="${TEMP_DIR}"
export MKDOCS_SOURCE_DIRECTORY
MKDOCS_TARGET_DIRECTORY="${REPOSITORY_ROOT_DIRECTORY_PATH}/docs"

RUN_CONTAINER_COMMAND=(
  docker run
  --rm
)

if [ -t 0 ]; then
  RUN_CONTAINER_COMMAND+=(
    --interactive
    --tty
  )
fi

RUN_CONTAINER_COMMAND+=(
  --name "mkdocs"
  --publish "8000:8000"
  --user "$(id -u)":"$(id -g)"
  --volume "${REPOSITORY_ROOT_DIRECTORY_PATH}":"${REPOSITORY_ROOT_DIRECTORY_PATH}"
  --volume "${MKDOCS_SOURCE_DIRECTORY}":/docs
  --volume "${MKDOCS_TARGET_DIRECTORY}":/mkdocs-output
  --volume /etc/localtime:/etc/localtime:ro
  "${MKDOCS_CONTAINER_IMAGE}"
)

DEFAULT_MKDOCS_ARGS=(
  --config-file "${MKDOCS_CONFIG_DIRECTORY}/mkdocs.yaml"
  --verbose
)

if [[ "${SUBCOMMAND}" == "serve" ]]; then
  RUN_CONTAINER_COMMAND+=(
    "serve"
    "--dev-addr=0.0.0.0:8000"
    "--strict"
    "${DEFAULT_MKDOCS_ARGS[@]}"
  )
elif [[ "${SUBCOMMAND}" == "build" ]]; then
  RUN_CONTAINER_COMMAND+=(
    "build"
    "--strict"
    "${DEFAULT_MKDOCS_ARGS[@]}"
  )
elif [[ "${SUBCOMMAND}" == "create" ]]; then
  RUN_CONTAINER_COMMAND+=(
    "new"
    .
  )
fi

echo "Setting up common files and directories"
ln -sf "${MKDOCS_CONFIG_DIRECTORY}/common" "${MKDOCS_SOURCE_DIRECTORY}/common"
ln -sf "${MKDOCS_CONFIG_DIRECTORY}/stylesheets" "${MKDOCS_SOURCE_DIRECTORY}/stylesheets"
ln -sf "${REPOSITORY_ROOT_DIRECTORY_PATH}/code-of-conduct.md" "${MKDOCS_SOURCE_DIRECTORY}/code-of-conduct.md"
ln -sf "${REPOSITORY_ROOT_DIRECTORY_PATH}/contributing.md" "${MKDOCS_SOURCE_DIRECTORY}/contributing.md"
ln -sf "${REPOSITORY_ROOT_DIRECTORY_PATH}/google6f50e7f14d085cc7.html" "${MKDOCS_SOURCE_DIRECTORY}/google6f50e7f14d085cc7.html"
ln -sf "${REPOSITORY_ROOT_DIRECTORY_PATH}/LICENSE" "${MKDOCS_SOURCE_DIRECTORY}/LICENSE"
ln -sf "${REPOSITORY_ROOT_DIRECTORY_PATH}/README.md" "${MKDOCS_SOURCE_DIRECTORY}/index.md"

PROJECTS_DIR="${REPOSITORY_ROOT_DIRECTORY_PATH}/reference-architectures"
echo "Searching for documentation in the projects directory: ${PROJECTS_DIR}"

PROJECTS_DESTINATION_DIR="${MKDOCS_SOURCE_DIRECTORY}/$(basename "${PROJECTS_DIR}")"
echo "Projects destination directory: ${PROJECTS_DESTINATION_DIR}"

for CURRENT_PROJECT_DIR in "${PROJECTS_DIR}"/*/; do
  PROJECT_DIRNAME="$(basename "$CURRENT_PROJECT_DIR")"
  echo "Searching for documentation for ${PROJECT_DIRNAME} in ${CURRENT_PROJECT_DIR}"
  if [[ -e "${CURRENT_PROJECT_DIR}/docs/index.md" || -e "${CURRENT_PROJECT_DIR}/docs/README.md" ]]; then
    echo "Found a docs directory in ${CURRENT_PROJECT_DIR}. Using it as is"
    ln -s "${CURRENT_PROJECT_DIR}/docs" "${PROJECTS_DESTINATION_DIR}/${PROJECT_DIRNAME}"
  elif [[ -f "${CURRENT_PROJECT_DIR}/README.md" ]]; then
    echo "Found a README.md in ${PROJECT_DIRNAME}. Using it as documentation together with other assets such as images"

    # We need the README and any referenced markdown or image files
    INCLUDED_FILES_ARGS=(-name "*.md" -o -name "*.png" -o -name "*.jpg" -o -name "*.svg")
    EXCLUDED_FILES_ARGS=(-iname "CHANGELOG*" -o -iname "LICENSE*" -o -iname "CONTRIBUTING*" -o -iname "TODO*")
    EXCLUDED_DIRS_ARGS=(-path "*/node_modules/*" -o -path "*/build/*" -o -path "*/venv/*")
    # Exclude vendored dependencies
    EXCLUDED_DIRS_ARGS+=(-o -path "*/fabric-modules/*")
    find "${CURRENT_PROJECT_DIR}" \
      \( "${INCLUDED_FILES_ARGS[@]}" \) \
      -a -not \( "${EXCLUDED_FILES_ARGS[@]}" \) \
      -a -not \( "${EXCLUDED_DIRS_ARGS[@]}" -prune \) \
      -print0 |
      while IFS= read -r -d $'\0' file; do
        # Strip the repository path from the file path
        FILE_RELATIVE_PATH="${file#"${PROJECTS_DIR}/"}"
        FILE_DESTINATION_PATH="${PROJECTS_DESTINATION_DIR}/${FILE_RELATIVE_PATH}"
        FILE_DESTINATION_DIRECTORY="$(dirname "${FILE_DESTINATION_PATH}")"
        mkdir --parents "${FILE_DESTINATION_DIRECTORY}"
        ln -sf "${file}" "${FILE_DESTINATION_DIRECTORY}"
      done
  fi
done

echo "Removing the old mkdocs target directory (${MKDOCS_TARGET_DIRECTORY})"
rm -rf "${MKDOCS_TARGET_DIRECTORY}"
mkdir --parents "${MKDOCS_TARGET_DIRECTORY}"

echo "Run container command: ${RUN_CONTAINER_COMMAND[*]}"
"${RUN_CONTAINER_COMMAND[@]}"
