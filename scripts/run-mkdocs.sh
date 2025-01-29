#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# renovate: datasource=docker packageName=squidfunk/mkdocs-material versioning=docker
MKDOCS_CONTAINER_IMAGE_VERSION="9.5.50"
MKDOCS_CONTAINER_IMAGE="squidfunk/mkdocs-material:${MKDOCS_CONTAINER_IMAGE_VERSION}"

echo "Running mkdocs: ${MKDOCS_CONTAINER_IMAGE}"

SUBCOMMAND="${1}"
echo "Subcommand: ${SUBCOMMAND}"

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
  --volume "$(pwd)":/docs
  --volume /etc/localtime:/etc/localtime:ro
  "${MKDOCS_CONTAINER_IMAGE}"
)

DEFAULT_MKDOCS_ARGS=(
  --config-file config/mkdocs/mkdocs.yaml
)

if [[ "${SUBCOMMAND}" == "serve" ]]; then
  RUN_CONTAINER_COMMAND+=(
    "serve"
    "--dev-addr=0.0.0.0:8000"
    "${DEFAULT_MKDOCS_ARGS[@]}"
  )
elif [[ "${SUBCOMMAND}" == "build" ]]; then
  RUN_CONTAINER_COMMAND+=(
    "build"
    "${DEFAULT_MKDOCS_ARGS[@]}"
  )
elif [[ "${SUBCOMMAND}" == "create" ]]; then
  RUN_CONTAINER_COMMAND+=(
    "new"
    .
  )
fi

echo "Run container command: ${RUN_CONTAINER_COMMAND[*]}"
"${RUN_CONTAINER_COMMAND[@]}"
