#!/bin/bash

set -e
set -u
set -o pipefail

readonly ROOT_DIR="$(cd "$(dirname "${0}")/.." && pwd)"
readonly DOCS_DIR="${ROOT_DIR}/docs"
readonly BIN_DIR="${ROOT_DIR}/.bin"
readonly SITE_DIR="${ROOT_DIR}/.site"

# shellcheck source=SCRIPTDIR/.util/tools.sh
source "${ROOT_DIR}/scripts/.util/tools.sh"

# shellcheck source=SCRIPTDIR/.util/print.sh
source "${ROOT_DIR}/scripts/.util/print.sh"

function main {
  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --help|-h)
        shift 1
        usage
        exit 0
        ;;

      "")
        # skip if the argument is empty
        shift 1
        ;;

      *)
        util::print::error "unknown argument \"${1}\""
    esac
  done

  website::clone

  util::tools::hugo::install --directory "${BIN_DIR}"

  gomod::replace

  website::serve
}

function usage() {
  cat <<-USAGE
docs.sh

Serves a local version of the Paketo site (paketo.io) using the content in the
docs/ subdirectory of this repo.

OPTIONS
  --help               -h            prints the command usage
USAGE
}

function website::clone() {
  if [[ ! -d "${SITE_DIR}" ]]; then
    util::print::title "Cloning paketo-website repo..."

    mkdir -p "${SITE_DIR}"
    git clone git@github.com:paketo-buildpacks/paketo-website "${SITE_DIR}"
  fi

  cd "${SITE_DIR}"
  git checkout main --force
  git pull origin main -r --force
  cd "${ROOT_DIR}"
}

function website::serve() {
  util::print::title "Serving local version of docs..."
  cd "${SITE_DIR}"
  hugo server -D
}

function gomod::replace() {
  util::print::title "Substituting local docs module in website go mod..."

  cd "${DOCS_DIR}"
  module="$(go mod edit -json | jq -r '.Module.Path')"

  cd "${SITE_DIR}"
  go mod edit -replace "${module}"="${DOCS_DIR}"
  cd "${ROOT_DIR}"
}

main "${@:-}"
