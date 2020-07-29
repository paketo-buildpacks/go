#!/usr/bin/env bash
set -eu
set -o pipefail

readonly PROGDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILDPACKDIR="$(cd "${PROGDIR}/.." && pwd)"

# shellcheck source=.util/tools.sh
source "${PROGDIR}/.util/tools.sh"

# shellcheck source=.util/print.sh
source "${PROGDIR}/.util/print.sh"

function main() {
  if [[ ! -d "${BUILDPACKDIR}/integration" ]]; then
      util::print::warn "** WARNING  No Integration tests **"
  fi

  tools::install
  images::pull
  tests::run
}

function tools::install() {
  util::tools::pack::install \
      --directory "${BUILDPACKDIR}/.bin"

  util::tools::jam::install \
      --directory "${BUILDPACKDIR}/.bin"
}

function images::pull() {
    util::print::title "Pulling builder image..."
    docker pull "${CNB_BUILDER_IMAGE:=index.docker.io/paketobuildpacks/builder:base}"

    util::print::title "Setting default pack builder image..."
    pack set-default-builder "${CNB_BUILDER_IMAGE}"

    local run_image lifecycle_image
    run_image="$(
      docker inspect "${CNB_BUILDER_IMAGE}" \
        | jq -r '.[0].Config.Labels."io.buildpacks.builder.metadata"' \
        | jq -r '.stack.runImage.image'
    )"
    lifecycle_image="index.docker.io/buildpacksio/lifecycle:$(
      docker inspect "${CNB_BUILDER_IMAGE}" \
        | jq -r '.[0].Config.Labels."io.buildpacks.builder.metadata"' \
        | jq -r '.lifecycle.version'
    )"

    util::print::title "Pulling run image..."
    docker pull "${run_image}"

    util::print::title "Pulling lifecycle image..."
    docker pull "${lifecycle_image}"
}

function tests::run() {
  util::print::title "Run Buildpack Runtime Integration Tests"
  pushd "${BUILDPACKDIR}" > /dev/null
      if GOMAXPROCS="${GOMAXPROCS:-4}" go test -count=1 -timeout 0 ./integration/... -v -run Integration; then
          util::print::success "** GO Test Succeeded **"
      else
          util::print::error "** GO Test Failed **"
      fi
  popd > /dev/null
}

main "${@:-}"
