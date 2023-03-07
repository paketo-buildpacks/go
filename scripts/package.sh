#!/bin/bash

set -e
set -u
set -o pipefail

readonly ROOT_DIR="$(cd "$(dirname "${0}")/.." && pwd)"
readonly BIN_DIR="${ROOT_DIR}/.bin"
readonly BUILD_DIR="${ROOT_DIR}/build"

# shellcheck source=SCRIPTDIR/.util/tools.sh
source "${ROOT_DIR}/scripts/.util/tools.sh"

# shellcheck source=SCRIPTDIR/.util/print.sh
source "${ROOT_DIR}/scripts/.util/print.sh"

function main {
  local version output token
  token=""

  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --version|-v)
        version="${2}"
        shift 2
        ;;

      --output|-o)
        output="${2}"
        shift 2
        ;;

      --token|-t)
        token="${2}"
        shift 2
        ;;

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

  if [[ -z "${version:-}" ]]; then
    usage
    echo
    util::print::error "--version is required"
  fi

  if [[ -z "${output:-}" ]]; then
    output="${BUILD_DIR}/buildpackage.cnb"
  fi

  repo::prepare

  tools::install "${token}"

  buildpack::archive "${version}"
  buildpackage::create "${output}"
}

function usage() {
  cat <<-USAGE
package.sh --version <version> [OPTIONS]

Packages the buildpack into a buildpackage .cnb file.

OPTIONS
  --help               -h            prints the command usage
  --version <version>  -v <version>  specifies the version number to use when packaging the buildpack
  --output <output>    -o <output>   location to output the packaged buildpackage artifact (default: ${ROOT_DIR}/build/buildpackage.cnb)
  --token <token>                    Token used to download assets from GitHub (e.g. jam, pack, etc) (optional)
USAGE
}

function repo::prepare() {
  util::print::title "Preparing repo..."

  rm -rf "${BUILD_DIR}"

  mkdir -p "${BIN_DIR}"
  mkdir -p "${BUILD_DIR}"

  export PATH="${BIN_DIR}:${PATH}"
}

function tools::install() {
  local token
  token="${1}"

  util::tools::jam::install \
    --directory "${BIN_DIR}" \
    --token "${token}"

  util::tools::pack::install \
    --directory "${BIN_DIR}" \
    --token "${token}"
}

function buildpack::archive() {
  local version
  version="${1}"

  util::print::title "Packaging buildpack into ${BUILD_DIR}/buildpack.tgz..."

  jam pack \
    --buildpack "${ROOT_DIR}/buildpack.toml" \
    --version "${version}" \
    --offline \
    --output "${BUILD_DIR}/buildpack.tgz"
}

function buildpackage::create() {
  local output
  output="${1}"

  util::print::title "Packaging buildpack..."

  pack \
    buildpack package "${output}" \
      --config "${ROOT_DIR}/package.toml" \
      --format file
}

main "${@:-}"
