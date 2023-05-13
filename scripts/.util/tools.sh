#!/usr/bin/env bash

set -eu
set -o pipefail

# shellcheck source=SCRIPTDIR/print.sh
source "$(dirname "${BASH_SOURCE[0]}")/print.sh"

function util::tools::os() {
  case "$(uname)" in
    "Darwin")
      echo "${1:-darwin}"
      ;;

    "Linux")
      echo "linux"
      ;;

    *)
      util::print::error "Unknown OS \"$(uname)\""
      exit 1
  esac
}

function util::tools::arch() {
  case "$(uname -m)" in
    arm64|aarch64)
      echo "arm64"
      ;;

    amd64|x86_64)
      if [[ "${1:-}" == "--blank-amd64" ]]; then
        echo ""
      else
        echo "amd64"
      fi
      ;;

    *)
      util::print::error "Unknown Architecture \"$(uname -m)\""
      exit 1
  esac
}

function util::tools::path::export() {
  local dir
  dir="${1}"

  if ! echo "${PATH}" | grep -q "${dir}"; then
    PATH="${dir}:$PATH"
    export PATH
  fi
}

function util::tools::jam::install() {
  local dir token
  token=""

  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --directory)
        dir="${2}"
        shift 2
        ;;

      --token)
        token="${2}"
        shift 2
        ;;

      *)
        util::print::error "unknown argument \"${1}\""
    esac
  done

  mkdir -p "${dir}"
  util::tools::path::export "${dir}"

  if [[ ! -f "${dir}/jam" ]]; then
    local version curl_args os arch

    version="$(jq -r .jam "$(dirname "${BASH_SOURCE[0]}")/tools.json")"

    curl_args=(
      "--fail"
      "--silent"
      "--location"
      "--output" "${dir}/jam"
    )

    if [[ "${token}" != "" ]]; then
      curl_args+=("--header" "Authorization: Token ${token}")
    fi

    util::print::title "Installing jam ${version}"

    os=$(util::tools::os)
    arch=$(util::tools::arch)

    curl "https://github.com/paketo-buildpacks/jam/releases/download/${version}/jam-${os}-${arch}" \
      "${curl_args[@]}"

    chmod +x "${dir}/jam"
  else
    util::print::info "Using $("${dir}"/jam version)"
  fi
}

function util::tools::pack::install() {
  local dir token
  token=""

  while [[ "${#}" != 0 ]]; do
    case "${1}" in
      --directory)
        dir="${2}"
        shift 2
        ;;

      --token)
        token="${2}"
        shift 2
        ;;

      *)
        util::print::error "unknown argument \"${1}\""
    esac
  done

  mkdir -p "${dir}"
  util::tools::path::export "${dir}"

  if [[ ! -f "${dir}/pack" ]]; then
    local version curl_args os arch

    version="$(jq -r .pack "$(dirname "${BASH_SOURCE[0]}")/tools.json")"

    tmp_location="/tmp/pack.tgz"
    curl_args=(
      "--fail"
      "--silent"
      "--location"
      "--output" "${tmp_location}"
    )

    if [[ "${token}" != "" ]]; then
      curl_args+=("--header" "Authorization: Token ${token}")
    fi

    util::print::title "Installing pack ${version}"

    os=$(util::tools::os macos)
    arch=$(util::tools::arch --blank-amd64)

    curl "https://github.com/buildpacks/pack/releases/download/${version}/pack-${version}-${os}${arch:+-$arch}.tgz" \
      "${curl_args[@]}"

    tar xzf "${tmp_location}" -C "${dir}"
    chmod +x "${dir}/pack"

    rm "${tmp_location}"
  else
    util::print::info "Using pack $("${dir}"/pack version)"
  fi
}

function util::tools::tests::checkfocus() {
  testout="${1}"
  if grep -q 'Focused: [1-9]' "${testout}"; then
    echo "Detected Focused Test(s) - setting exit code to 197"
    rm "${testout}"
    util::print::success "** GO Test Succeeded **" 197
  fi
  rm "${testout}"
}
