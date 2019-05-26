# This module contains utility functions for ensuring the compatibility with
# OSX systems.
#
# Dependencies:
#   None
#
# vim: ft=sh

COREUTILS_GNUBIN="/usr/local/opt/coreutils/libexec/gnubin"
SED_GNUBIN="/usr/local/opt/gnu-sed/libexec/gnubin"
GREP_GNUBIN="/usr/local/opt/grep/libexec/gnubin"
UNAME="uname"

#######################################
# Update PATH variable environment with the
# COREUTILS_GNUBIN, GREP_GNUBIN, SED_GNUBIN directories.
# This function is useful for OSX systems in order to ensure that
# GNU executables have major priority against the local executables.
#
# Globals:
#   PATH   (WO)           : Put the GNUBIN directories in top of the PATH variable.
#   COREUTILS_GNUBIN (RO) : The COREUTILS_GNUBIN directory.
#   GREP_GNUBIN (RO)      : The GREP_GNUBIN directory.
#   SED_GNUBIN (RO)       : The SED_GNUBIN directory.
# Arguments:
#   None
# Returns:
#   None
# Output:
#   None
#######################################
function osx_update_path() {
    [[ -d "$COREUTILS_GNUBIN" ]] && PATH="$COREUTILS_GNUBIN:$PATH"
    [[ -d "$GREP_GNUBIN" ]] && PATH="$GREP_GNUBIN:$PATH"
    [[ -d "$SED_GNUBIN" ]] && PATH="$SED_GNUBIN:$PATH"
    return 0
}


#######################################
# Attempt to execute the given command first using the one located
# in GNUBIN directories.
# If the executable does not exist in GNUBIN, the function attempts
# to execute the command located in the usual paths defined by PATH variable.
#
# This function is useful for OSX systems in order to ensure that
# GNU executables have major priority against the local executables.
#
# The difference with `osx_update_path` is that the current function does
# not pollute PATH variable.
#
# Globals:
#   COREUTILS_GNUBIN (RO) : The COREUTILS_GNUBIN directory.
#   GREP_GNUBIN (RO)      : The GREP_GNUBIN directory.
#   SED_GNUBIN (RO)       : The SED_GNUBIN directory.
# Arguments:
#   cmd  ($1)    : The command to execute.
#   args ($2-)   : The command arguments.
# Returns:
#   -            : The command return.
# Output:
#   -            : The command output.
#######################################
function osx_attempt_command() {
    local cmd=$1
    shift
    if [[ -x "$COREUTILS_GNUBIN/$cmd" ]]
    then
        "$COREUTILS_GNUBIN/$cmd" "$@"
    elif [[ -x "$SED_GNUBIN/$cmd" ]]
    then
        "$SED_GNUBIN/$cmd" "$@"
    elif [[ -x "$GREP_GNUBIN/$cmd" ]]
    then
        "$GREP_GNUBIN/$cmd" "$@"
    else
        $cmd "$@"
    fi
}


#######################################
# Detect whether the function runs in a OSX os or not.
#
# Globals:
#   UNAME (RO)   : The UNAME command.
# Arguments:
#   None
# Returns:
#   0            : If the function runs in OSX
#   1            : If the function does not run in OSX
# Output:
#   -            : The command output.
#######################################
function osx_detect() {
    [[ $($UNAME) == 'Darwin' ]]
}
