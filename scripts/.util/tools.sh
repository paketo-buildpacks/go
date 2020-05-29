#!/usr/bin/env bash

set -eu
set -o pipefail

# shellcheck source=./print.sh
source "$(dirname "${BASH_SOURCE[0]}")/print.sh"

function util::tools::path::export() {
    local dir
    dir="${1}"

    if ! echo "${PATH}" | grep -q "${dir}"; then
        PATH="${dir}:$PATH"
        export PATH
    fi
}

function util::tools::jam::install () {
  echo "-> Installing v0.0.10 jam..."

  local dir
  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --directory)
        dir="${2}"
        shift 2
        ;;

      *)
        util::print::error "unknown argument \"${1}\""
    esac
  done

  local os
  case "$(uname)" in
    "Darwin")
      os="darwin"
      ;;

    "Linux")
      os="linux"
      ;;

    *)
      echo "Unknown OS \"$(uname)\""
      exit 1
  esac

  mkdir -p "${dir}"
  util::tools::path::export "${dir}"

  if [[ ! -f "${dir}/jam" ]]; then
    local version
    version="v0.0.10"

    util::print::title "Installing jam ${version}"
    curl "https://github.com/paketo-buildpacks/packit/releases/download/${version}/jam-${os}" \
      --silent \
      --location \
      --output "${dir}/jam"
    chmod +x "${dir}/jam"
  fi
}

function util::tools::pack::install() {
  local dir
  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --directory)
        dir="${2}"
        shift 2
        ;;

      *)
        util::print::error "unknown argument \"${1}\""
    esac
  done

  mkdir -p "${dir}"
  util::tools::path::export "${dir}"

  local os
  case "$(uname)" in
    "Darwin")
      os="macos"
      ;;

    "Linux")
      os="linux"
      ;;

    *)
      echo "Unknown OS \"$(uname)\""
      exit 1
  esac

  if [[ ! -f "${dir}/pack" ]]; then
    local version
    version="v0.10.0"

    util::print::title "Installing pack ${version}"
    curl "https://github.com/buildpacks/pack/releases/download/${version}/pack-v0.10.0-${os}.tgz" \
      --silent \
      --location \
      --output /tmp/pack.tgz
    tar xzf /tmp/pack.tgz -C "${dir}"
    chmod +x "${dir}/pack"
    rm /tmp/pack.tgz
  fi
}

function util::tools::packager::install () {
    local dir
    while [[ "${#}" != 0 ]]; do
      case "${1}" in
        --directory)
          dir="${2}"
          shift 2
          ;;

        *)
          util::print::error "unknown argument \"${1}\""
      esac
    done

    mkdir -p "${dir}"
    util::tools::path::export "${dir}"

    if [[ ! -f "${dir}/packager" ]]; then
        util::print::title "Installing packager"
        GOBIN="${dir}" go install github.com/cloudfoundry/libcfbuildpack/packager
    fi
}
