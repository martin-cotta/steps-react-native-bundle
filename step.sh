#!/bin/bash

set -e

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
    key=$1
    value=$2
    if [ -z "${value}" ] ; then
        echo_fail "Missing required input: ${key}"
    fi
}

function escape {
    token=$1
    quoted=$(echo "${token}" | sed -e 's/\"/\\"/g' )
    echo "${quoted}"
}

function validate_required_input_with_options {
    key=$1
    value=$2
    options=$3

    validate_required_input "${key}" "${value}"

    found="0"
    for option in "${options[@]}" ; do
        if [ "${option}" == "${value}" ] ; then
            found="1"
        fi
    done

    if [ "${found}" == "0" ] ; then
        echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
    fi
}

#=======================================
# Main
#=======================================

echo_info "Configs:"
echo_details "- Platform: $platform"
echo_details "- EntryFile: $entry_file"
echo_details "- BundleOutput: $bundle_output"
echo_details "- SourcemapOutput: $sourcemap_output"
echo_details "- AssetsDest: $assets_dest"
echo_details "- Dev: $dev"

values=("ios"  "android")
validate_required_input_with_options "platform" $platform "${values[@]}"
validate_required_input "entry_file" $entry_file
validate_required_input "bundle_output" $bundle_output
validate_required_input "sourcemap_output" $sourcemap_output
validate_required_input "assets_dest" $assets_dest

mkdir -p "$(dirname "${bundle_output}")"
mkdir -p "$(dirname "${sourcemap_output}")"
mkdir -p "$(dirname "${assets_dest}")"

echo_info "react-native CLI version: $(npx react-native --version)"

echo

set -x

npx react-native bundle \
  --entry-file ${entry_file} \
  --platform ${platform} \
  --dev ${dev} \
  --reset-cache \
  --bundle-output "${bundle_output}" \
  --sourcemap-output "${sourcemap_output}" \
  --assets-dest "${assets_dest}"

{ set +x; } 2>/dev/null

if [[ $bundle_output != /* ]]; then
	bundle_output="$(pwd)/$bundle_output"
fi

if [[ $sourcemap_output != /* ]]; then
	sourcemap_output="$(pwd)/$sourcemap_output"
fi

if [[ $assets_dest != /* ]]; then
	assets_dest="$(pwd)/$assets_dest"
fi

envman add --key RN_BUNDLE_FILE_PATH --value "$bundle_output"
envman add --key RN_BUNDLE_SOURCEMAP_FILE_PATH --value "$sourcemap_output"
envman add --key RN_BUNDLE_ASSETS_PATH --value "$assets_dest"

echo_info "Output:"
echo_details "- RN_BUNDLE_FILE_PATH: $bundle_output"
echo_details "- RN_BUNDLE_SOURCEMAP_FILE_PATH: $sourcemap_output"
echo_details "- RN_BUNDLE_ASSETS_PATH: $assets_dest"