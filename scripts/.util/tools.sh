#!/usr/bin/env bash

set -eu
set -o pipefail

# shellcheck source=SCRIPTDIR/print.sh
source "$(dirname "${BASH_SOURCE[0]}")/print.sh"

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
    local version curl_args

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

    curl "https://github.com/paketo-buildpacks/jam/releases/download/${version}/jam-${os}" \
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
    local version curl_args

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

    curl "https://github.com/buildpacks/pack/releases/download/${version}/pack-${version}-${os}.tgz" \
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
