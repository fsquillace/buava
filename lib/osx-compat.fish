# This module contains utility functions for ensuring the compatibility with
# OSX systems.
#
# Dependencies:
#   None
#
# vim: ft=sh

set COREUTILS_GNUBIN "/usr/local/opt/coreutils/libexec/gnubin"
set SED_GNUBIN "/usr/local/opt/gnu-sed/libexec/gnubin"
set GREP_GNUBIN "/usr/local/opt/grep/libexec/gnubin"
set UNAME "uname"

#######################################
# Update PATH variable environment with the
# COREUTILS_GNUBIN, GREP_GNUBIN, SED_GNUBIN directories.
# This function is useful for OSX systems in order to ensure that
# GNU executables have major priority against the local executables.
#
# Globals:
#   PATH   (WO)     : Put the GNUBIN directory in top of the PATH variable.
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
function osx_update_path
    [ -d "$COREUTILS_GNUBIN" ]; and set PATH $COREUTILS_GNUBIN $PATH
    [ -d "$SED_GNUBIN" ]; and set PATH $SED_GNUBIN $PATH
    [ -d "$GREP_GNUBIN" ]; and set PATH $GREP_GNUBIN $PATH
    return 0
end


#######################################
# Attempt to execute the given command first using the one located in GNUBIN
# directories.
# If the executable does not exist in GNUBIN, the function attempts
# to execute the command located in the usual paths defined by PATH variable.
#
# This function is useful for OSX systems in order to ensure that
# GNU executables have major priority against the local executables.
#
# The difference with osx_update_path is that the current function does
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
function osx_attempt_command
    set -l cmd $argv[1]
    set --erase argv[1]
    if [ -x "$COREUTILS_GNUBIN/$cmd" ]
        eval "$COREUTILS_GNUBIN/$cmd" $argv
    else if [ -x "$SED_GNUBIN/$cmd" ]
        eval "$SED_GNUBIN/$cmd" $argv
    else if [ -x "$GREP_GNUBIN/$cmd" ]
        eval "$GREP_GNUBIN/$cmd" $argv
    else
        eval $cmd $argv
    end
end


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
function osx_detect
    set -l uname_res (eval $UNAME)
    if [ $uname_res = 'Darwin' ]
        return 0
    else
        return 1
    end
end
