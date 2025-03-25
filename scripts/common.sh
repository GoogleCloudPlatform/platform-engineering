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

# Don't set errexit so we can source this from interactive shells without
# causing the shell to exit on errors
set -o nounset
set -o pipefail

# renovate: datasource=docker packageName=squidfunk/mkdocs-material versioning=docker
MKDOCS_CONTAINER_IMAGE_VERSION="9.5.50"
# shellcheck disable=SC2034 # variable is used in other scripts
MKDOCS_CONTAINER_IMAGE="squidfunk/mkdocs-material:${MKDOCS_CONTAINER_IMAGE_VERSION}"

# shellcheck disable=SC2034
MKDOCS_IGNORE_IF_ONLY_CHANGED_FILES=(
  "docs/sitemap.xml"
  "docs/sitemap.xml.gz"
)

check_if_uncommitted_files_only_include_files() {
  local -a FILES_TO_CHECK=("$@")
  local -a CHANGED_FILES

  git status

  readarray -d '' -t CHANGED_FILES < <(git diff-files -z --name-only)
  readarray -d '' -t SORTED_CHANGED_FILES < <(printf '%s\0' "${CHANGED_FILES[@]}" | sort -z)

  echo "Changed files (${#SORTED_CHANGED_FILES[@]}) in working directory:"
  echo "${SORTED_CHANGED_FILES[*]}"

  readarray -d '' -t SORTED_FILES_TO_CHECK < <(printf '%s\0' "${FILES_TO_CHECK[@]}" | sort -z)

  if [[ "${SORTED_CHANGED_FILES[*]}" == "${SORTED_FILES_TO_CHECK[*]}" ]]; then
    echo "Working directory contains only the files to check"
    return 0
  else
    echo "Working directory doesn't contain only the files to check"
    return 1
  fi
}

check_if_uncommitted_files_only_include_files_to_ignore() {
  if check_if_uncommitted_files_only_include_files "${MKDOCS_IGNORE_IF_ONLY_CHANGED_FILES[@]}"; then
    return 0
  else
    return 1
  fi
}

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
