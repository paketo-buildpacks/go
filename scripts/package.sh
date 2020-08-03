#!/bin/bash

set -e
set -u
set -o pipefail

readonly ROOT_DIR="$(cd "$(dirname "${0}")/.." && pwd)"
readonly BIN_DIR="${ROOT_DIR}/.bin"
readonly BUILD_DIR="${ROOT_DIR}/build"

# shellcheck source=.util/tools.sh
source "${ROOT_DIR}/scripts/.util/tools.sh"

# shellcheck source=.util/print.sh
source "${ROOT_DIR}/scripts/.util/print.sh"

function main {
  local version

  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --version|-v)
        version="${2}"
        shift 2
        ;;

      "")
        # skip if the argument is empty
        shift 1
        ;;

      *)
        util::print::error "unknown argument \"${1}\""
    esac
  done

  if [[ "${version:-}" == "" ]]; then
    util::print::error "--version is required"
  fi

  repo::prepare

  util::tools::pack::install --directory "${BIN_DIR}"

  buildpack::archive "${version}"
  buildpackage::create
}

function repo::prepare() {
  util::print::title "Preparing repo..."

  rm -rf "${BUILD_DIR}"

  mkdir -p "${BIN_DIR}"
  mkdir -p "${BUILD_DIR}"

  export PATH="${BIN_DIR}:${PATH}"
}

function buildpack::archive() {
  local version
  version="${1}"

  util::print::title "Packaging buildpack into ${BUILD_DIR}/buildpack.tgz..."

  util::tools::jam::install --directory "${BIN_DIR}"

  jam pack \
    --buildpack "${ROOT_DIR}/buildpack.toml" \
    --version "${version}" \
    --offline \
    --output "${BUILD_DIR}/buildpack.tgz"
}

function buildpackage::create() {
  util::print::title "Packaging buildpack..."

  pack \
    package-buildpack "${BUILD_DIR}/buildpackage.cnb" \
      --config "${ROOT_DIR}/package.toml" \
      --format file
}

main "${@:-}"
