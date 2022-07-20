#!/usr/bin/env bash
set -eu
set -o pipefail

readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILDPACKDIR="$(cd "${PROGDIR}/.." && pwd)"

# shellcheck source=SCRIPTDIR/.util/tools.sh
source "${PROGDIR}/.util/tools.sh"

# shellcheck source=SCRIPTDIR/.util/print.sh
source "${PROGDIR}/.util/print.sh"

# shellcheck source=SCRIPTDIR/.util/builders.sh
source "${PROGDIR}/.util/builders.sh"

function main() {
  local builderArray
  builderArray=()
  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --help|-h)
        shift 1
        usage
        exit 0
        ;;

      --builder|-b)
        builderArray+=("${2}")
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

  if [[ ! -d "${BUILDPACKDIR}/integration" ]]; then
    util::print::warn "** WARNING  No Integration tests **"
  fi

  tools::install

  if [ ${#builderArray[@]} -eq 0 ]; then
    util::print::title "No builders provided. Finding builders in integration.json..."

    local builders
    builders="$(util::builders::list "${BUILDPACKDIR}/integration.json" | jq -r '.[]' )"

    # shellcheck disable=SC2206
    IFS=$'\n' builderArray=(${builders})
    unset IFS
  fi

  # shellcheck disable=SC2068
  images::pull ${builderArray[@]}

  local testout
  testout=$(mktemp)
  for builder in "${builderArray[@]}"; do
    util::print::title "Setting default pack builder image..."
    pack config default-builder "${builder}"

    tests::run "${builder}" "${testout}"
  done

  util::tools::tests::checkfocus "${testout}"
  util::print::success "** GO Test Succeeded with all builders**"
}

function usage() {
  cat <<-USAGE
integration.sh [OPTIONS]

Runs the integration test suite.

OPTIONS
  --help           -h         prints the command usage
  --builder <name> -b <name>  sets the name of the builder(s) that are pulled / used for testing.
                              Defaults to "builders" array in integration.json, if present.
USAGE
}

function tools::install() {
  util::tools::pack::install \
    --directory "${BUILDPACKDIR}/.bin"

  util::tools::jam::install \
    --directory "${BUILDPACKDIR}/.bin"
}

function images::pull() {
  for builder in "${@}"; do
    util::print::title "Pulling builder image ${builder}..."
    docker pull "${builder}"

    local run_image lifecycle_image
    run_image="$(
      pack inspect-builder "${builder}" --output json \
        | jq -r '.remote_info.run_images[0].name'
    )"
    lifecycle_image="index.docker.io/buildpacksio/lifecycle:$(
      pack inspect-builder "${builder}" --output json \
        | jq -r '.remote_info.lifecycle.version'
    )"

    util::print::title "Pulling run image..."
    docker pull "${run_image}"

    util::print::title "Pulling lifecycle image..."
    docker pull "${lifecycle_image}"
  done
}

function tests::run() {
  util::print::title "Run Buildpack Runtime Integration Tests"
  util::print::info "Using ${1} as builder..."

  pushd "${BUILDPACKDIR}" > /dev/null
    #shellcheck disable=SC2068
    if GOMAXPROCS="${GOMAXPROCS:-4}" go test -count=1 -timeout 0 ./integration/... -v -run Integration | tee "${2}"; then
      util::print::info "** GO Test Succeeded with ${1}**"
    else
      util::print::error "** GO Test Failed with ${1}**"
    fi
  popd > /dev/null
}

main "${@:-}"
