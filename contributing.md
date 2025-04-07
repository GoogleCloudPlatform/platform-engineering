# How to Contribute

We'd love to accept your patches and contributions to this project.

## Before you begin

### Sign our Contributor License Agreement

Contributions to this project must be accompanied by a
[Contributor License Agreement](https://cla.developers.google.com/about) (CLA).
You (or your employer) retain the copyright to your contribution; this simply
gives us permission to use and redistribute your contributions as part of the
project.

If you or your current employer have already signed the Google CLA (even if it
was for a different project), you probably don't need to do it again.

Visit <https://cla.developers.google.com/> to see your current agreements or to
sign a new one.

### Review our Community Guidelines

This project follows
[Google's Open Source Community Guidelines](https://opensource.google/conduct/).

## Contribution process

### Code Reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

## Development guide

This document contains technical information to contribute to this repository.

### Site

This repository includes scripts and configuration to build a site using
[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/):

- `config/mkdocs`: MkDocs configuration files
- `scripts/run-mkdocs.sh`: script to build the site
- `.github/workflows/documentation.yaml`: GitHub Actions workflow that builds
  the site, and pushes a commit with changes on the current branch.

#### Build the site

To build the site, run the following command from the root of the repository:

```bash
scripts/run-mkdocs.sh
```

#### Preview the site

To preview the site, run the following command from the root of the repository:

```bash
scripts/run-mkdocs.sh "serve"
```

### Linting and formatting

We configured several linters and formatters for code and documentation in this
repository. Linting and formatting checks run as part of CI workflows.

Linting and formatting checks are configured to check changed files only by
default. If you change the configuration of any linter or formatter, these
checks run against the entire repository.

To run linting and formatting checks locally, you do the following:

```sh
scripts/lint.sh
```

To automatically fix certain linting and formatting errors, you do the
following:

```sh
LINTER_CONTAINER_FIX_MODE="true" scripts/lint.sh
```
