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

$NI credentials config -d "${WORKDIR}/creds"

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
[ -z "${BOLT_NAME}" ] && usage "spec: specify \`name\`, the name of the Bolt ${BOLT_TYPE} to run"

# Boltdir configuration
GIT=$(ni get -p {.git})
if [ -n "${GIT}" ]; then
  ni git clone
  NAME=$(ni get -p {.git.name})
  PROJECT_DIR="$( $NI get -p '{ .projectDir }' )"
  BOLTDIR="/workspace/${NAME}/${PROJECT_DIR}"
  BOLT_ARGS+=( "--project=${BOLTDIR}" )
fi

INSTALL_MODULES="$( $NI get -p '{ .installModules }' )"
if [[ "${INSTALL_MODULES}" == "true" ]]; then
    $BOLT module install "${BOLT_ARGS[@]}"
fi

MODULE_PATH="$( $NI get | $JQ -r 'try .modulePaths | join(":")' )"
[ -n "${MODULE_PATH}" ] && BOLT_ARGS+=( "--modulepath=${MODULE_PATH}" )

# Do not pollute our project directory with rerun info that we can't use.
BOLT_ARGS+=( --no-save-rerun )

# Running in non-interactive mode, so do not request a TTY.
BOLT_ARGS+=( --no-tty )

declare -a NI_OUTPUT_ARGS
FORMAT="$( $NI get -p '{ .format }' )"
if [ -n "${FORMAT}" ]; then
  BOLT_ARGS+=( "--format=${FORMAT}" )
else
  BOLT_ARGS+=( "--format=json" )
  NI_OUTPUT_ARGS+=( "--json" )
fi

# Parameter configuration
PARAMS="$( $NI get | jq 'try .parameters // empty' )"
[ -n "${PARAMS}" ] && BOLT_ARGS+=( "--params=${PARAMS}" )

# Transport configuration
TRANSPORT_TYPE="$( $NI get -p '{ .transport.type }' )"
[ -n "${TRANSPORT_TYPE}" ] && BOLT_ARGS+=( "--transport=${TRANSPORT_TYPE}" )

TRANSPORT_USER="$( $NI get -p '{ .transport.user }' )"
[ -n "${TRANSPORT_USER}" ] && BOLT_ARGS+=( "--user=${TRANSPORT_USER}" )

TRANSPORT_PASSWORD="$( $NI get -p '{ .transport.password }' )"
[ -n "${TRANSPORT_PASSWORD}" ] && BOLT_ARGS+=( "--password=${TRANSPORT_PASSWORD}" )

TRANSPORT_RUN_AS="$( $NI get -p '{ .transport.run_as }' )"
[ -n "${TRANSPORT_RUN_AS}" ] && BOLT_ARGS+=( "--run-as=${TRANSPORT_RUN_AS}" )

case "${TRANSPORT_TYPE}" in
ssh)
  TRANSPORT_PRIVATE_KEY="$( $NI get -p '{ .transport.privateKey }' )"
  if [ -n "${TRANSPORT_PRIVATE_KEY}" ]; then
    if [[ "${TRANSPORT_PRIVATE_KEY}" != /* ]]; then
      TRANSPORT_PRIVATE_KEY="${WORKDIR}/creds/${TRANSPORT_PRIVATE_KEY}"
    fi

    BOLT_ARGS+=( "--private-key=${TRANSPORT_PRIVATE_KEY}" )
  fi

  TRANSPORT_VERIFY_HOST="$( $NI get -p '{ .transport.verifyHost }' )"
  [[ "${TRANSPORT_VERIFY_HOST}" == "false" ]] && BOLT_ARGS+=( --no-host-key-check )
  ;;
winrm)
  TRANSPORT_USE_SSL="$( $NI get -p '{ .transport.useSSL }' )"
  [[ "${TRANSPORT_USE_SSL}" == "false" ]] && BOLT_ARGS+=( --no-ssl )

  TRANSPORT_VERIFY_HOST="$( $NI get -p '{ .transport.verifyHost }' )"
  [[ "${TRANSPORT_VERIFY_HOST}" == "false" ]] && BOLT_ARGS+=( --no-ssl-verify )
  ;;
'')
  ;;
*)
  ni log fatal "unsupported transport \"${TRANSPORT_TYPE}\" (if this transport is supported by Bolt, try adding it to your bolt.yaml file)"
  ;;
esac

# Target configuration
TARGETS="$( $NI get | $JQ -r 'try .targets | if type == "string" then . else join(",") end' )"
[ -n "${TARGETS}" ] && BOLT_ARGS+=( "--targets=${TARGETS}" )

echo "Running command: $BOLT ${BOLT_TYPE} run ${BOLT_NAME} ${BOLT_ARGS[@]}"

# Run Bolt!
BOLT_OUTPUT=$($BOLT "${BOLT_TYPE}" run "${BOLT_NAME}" "${BOLT_ARGS[@]}")

# Make the step fail if the Bolt command returns non-zero exit code
if [[ $? -ne 0 ]]; then
    echo "$BOLT_OUTPUT"
    exit 1
fi

$NI output set --key output --value "$BOLT_OUTPUT" "${NI_OUTPUT_ARGS[@]}"
