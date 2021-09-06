#!/bin/bash

#
# Commands
#

BOLT="${BOLT:-bolt}"
JQ="${JQ:-jq}"
NI="${NI:-ni}"

echo "Using Puppet Bolt version: $($BOLT --version)"

#
# Variables
#

WORKDIR="${WORKDIR:-/workspace}"

#
#
#
usage() {
  echo "usage: $@" >&2
  exit 1
}

declare -a BOLT_ARGS

BOLT_TYPE="$( $NI get -p '{ .type }' )"
case "${BOLT_TYPE}" in
task|plan)
  ;;
'')
  usage 'spec: specify `type`, one of "task" or "plan", the type of Bolt run to perform'
  ;;
*)
  ni log fatal "unsupported type \"${BOLT_TYPE}\"; cannot run this"
  ;;
esac

BOLT_NAME="$( $NI get -p '{ .name }' )"

GIT=$(ni get -p {.git})
if [ -n "${GIT}" ]; then
  ni git clone
  NAME=$(ni get -p {.git.name})
  PROJECT_DIR="$( $NI get -p '{ .projectDir }' )"
  BOLTDIR="/workspace/${NAME}/${PROJECT_DIR}"
  BOLT_ARGS+=( "--project=${BOLTDIR}" )
fi

MODULE_PATH="$( $NI get | $JQ -r 'try .modulePaths | join(":")' )"
[ -n "${MODULE_PATH}" ] && BOLT_ARGS+=( "--modulepath=${MODULE_PATH}" )

INSTALL_MODULES="$( $NI get -p '{ .installModules }' )"
if [[ "${INSTALL_MODULES}" == "true" ]]; then
    $BOLT module install "${BOLT_ARGS[@]}"
fi

echo "Running command: $BOLT ${BOLT_TYPE} show ${BOLT_NAME} ${BOLT_ARGS[@]}"

$BOLT ${BOLT_TYPE} show $BOLT_NAME "${BOLT_ARGS[@]}"
