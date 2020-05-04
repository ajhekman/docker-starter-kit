#!/usr/bin/env bash

# Set this to the main command expected to run from docker run
# E.G. 'rails' or 'serve' (can be abstract)
MAIN_CMD='./your-application'
INITIAL_SETUP_FILE='.docker_inital_setup_completed'


function main() {
  # "This is the entrypoint script for your docker container"
  # "It allows you to do whatever setup you may need before"
  # "starting your application."
  # "To disable debug statements, set LOG_LEVEL to 6"
  if [ -n "${APP_DIR:-}" ]; then
    export PATH="${APP_DIR}:${APP_DIR}/bin:${APP_DIR}/docker-bin:$(pwd)/bin:${PATH}"
    debug "PATH is: ${PATH}"
  fi

  if [ "$1" = "${MAIN_CMD}" ]; then
    debug "Preparing to run ${MAIN_CMD}"
    if [ ! -f "${INITIAL_SETUP_FILE}" ]; then
      info "*** Initial setup ***"
      debug "Put any initial / one time setup for the docker container here"
      debug "You may want to customize the conditional for running initial setup"
      info "PWD: $(pwd)"
      touch "${INITIAL_SETUP_FILE}"
    else
      info "Skipping initial setup: already performed."
    fi
    # debug "Checking and installing applicaiton dependencies"
    bundle check || bundle install

    # if the MAIN_CMD is 'serve' but you really want 'rails' uncomment these lines
    # shift
    # exec rails "$@"
  fi

  info "Handing over control via: 'exec ${@}'"
  exec "$@"

}

alias cp="cp --no-clobber"
alias mkdir="mkdir -p"

###############################################################################
# Based on a template by BASH3 Boilerplate v2.4.1
# http://bash3boilerplate.sh/#authors
#
# BASH3 Boilerplate Copyright (c) 2013 Kevin van Zonneveld and contributors
# You are not obligated to bundle the LICENSE file with your b3bp projects as long
# as you leave these references intact in the header comments of your source files.

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

# Define the environment variables (and their defaults) that this script depends on
LOG_LEVEL="${LOG_LEVEL:-7}" # 7 = debug -> 0 = emergency
NO_COLOR="${NO_COLOR:-}"    # true = disable color. otherwise autodetected


### Functions
##############################################################################

function __b3bp_log () {
  local log_level="${1}"
  shift

  local color_debug="\\x1b[35m"
  local color_info="\\x1b[32m"
  local color_error="\\x1b[31m"
  local color_emergency="\\x1b[1;4;5;37;41m"

  local colorvar="color_${log_level}"

  local color="${!colorvar:-${color_error}}"
  local color_reset="\\x1b[0m"

  if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]]; } || [[ ! -t 2 ]]; then
    if [[ "${NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      color=""; color_reset=""
    fi
  fi

  # all remaining arguments are to be printed
  local log_line=""

  while IFS=$'\n' read -r log_line; do
    # echo with date time
    # protip: add `-u` to `date` to switch to UTC
    echo -e "$(date +"%Y-%m-%d %H:%M:%S %Z") ${color}$(printf "[%9s]" "${log_level}")${color_reset} ${log_line}" 1>&2

    # echo with time
    # echo -e "$(date +"%H:%M:%S %Z") ${color}$(printf "[%9s]" "${log_level}")${color_reset} ${log_line}" 1>&2

    # echo without dates or time
    # echo -e "${color}$(printf "[%9s]" "${log_level}")${color_reset} ${log_line}" 1>&2
  done <<< "${@:-}"
}

function emergency () {                                __b3bp_log emergency "${@}"; exit 1; }
function error ()     { [[ "${LOG_LEVEL:-0}" -ge 3 ]] && __b3bp_log error "${@}"; true; }
function info ()      { [[ "${LOG_LEVEL:-0}" -ge 6 ]] && __b3bp_log info "${@}"; true; }
function debug ()     { [[ "${LOG_LEVEL:-0}" -ge 7 ]] && __b3bp_log debug "${@}"; true; }



### Signal trapping and backtracing
##############################################################################

function __b3bp_cleanup_before_exit () {
  # NOTE: this will not run if you use exec to launch your application
  debug "Cleaning up. Done"
}
trap __b3bp_cleanup_before_exit EXIT

# requires `set -o errtrace`
__b3bp_err_report() {
    local error_code=${?}
    error "Error in ${0} in function ${1} on line ${2}"
    exit ${error_code}
}
# Uncomment the following line for always providing an error backtrace
trap '__b3bp_err_report "${FUNCNAME:-.}" ${LINENO}' ERR


### Validation. Error out if the things required for your script are not present
##############################################################################

[[ "${LOG_LEVEL:-}" ]] || emergency "Cannot continue without LOG_LEVEL. "


### Runtime
##############################################################################


main "$@"
