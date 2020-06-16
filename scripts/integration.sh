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
  util::print::title "Pulling build image..."
  docker pull "${CNB_BUILD_IMAGE:=gcr.io/paketo-buildpacks/build:full-cnb-cf}"

  util::print::title "Pulling run image..."
  docker pull "${CNB_RUN_IMAGE:=gcr.io/paketo-buildpacks/run:full-cnb-cf}"

  util::print::title "Pulling cflinuxfs3 builder image..."
  docker pull "${CNB_BUILDER_IMAGE:=gcr.io/paketo-buildpacks/builder:cflinuxfs3}"

  export CNB_BUILD_IMAGE
  export CNB_RUN_IMAGE
  export CNB_BUILDER_IMAGE

  util::print::title "Setting default pack builder image..."
  pack set-default-builder "${CNB_BUILDER_IMAGE}"
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
