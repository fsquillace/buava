#!/usr/bin/env bash
ROOT_LOCATION="$(dirname $0)/../.."

source "$ROOT_LOCATION/tests/bunit/utils/utils.sh"

# Disable the exiterr
set +e

function oneTimeSetUp(){
    setUpUnitTests
}

function setUp(){
    GNUBIN=$(TMPDIR=/tmp mktemp -d -t osx-test-gnubin.XXXXXXX)
}

function tearDown(){
    rm -rf "$GNUBIN"
    unset GNUBIN
}

function fish_wrapper(){
    echo "$@" > "${OUTPUT_DIR}/fish_command"
    fish ${OUTPUT_DIR}/fish_command
}

function test_osx_update_path_gnubin_no_exists() {
    assertCommandSuccess fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; set GNUBIN 'not-a-directory'; osx_update_path; echo \$PATH"
    assertEquals "$(fish_wrapper "echo \$PATH")" "$(cat $STDOUTF)"
}

function test_osx_update_path() {
    assertCommandSuccess fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; set GNUBIN '$GNUBIN'; osx_update_path; echo \$PATH"
    assertEquals "$(fish_wrapper "echo $GNUBIN \$PATH")" "$(cat $STDOUTF)"
}

function test_osx_attempt_command() {
    assertCommandSuccess fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; set GNUBIN '$GNUBIN'; osx_attempt_command ls"
}

function test_osx_attempt_command_not_a_command() {
    assertCommandFailOnStatus 127 fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; set GNUBIN '$GNUBIN'; osx_attempt_command nocmd"
}

function test_osx_attempt_command_on_gnubin() {
    cat <<EOF > $GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $GNUBIN/mycmd
    assertCommandSuccess fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; set GNUBIN '$GNUBIN'; osx_attempt_command mycmd"
    assertEquals "mycommand" "$(cat $STDOUTF)"
    cat $STDERRF
}

function test_osx_attempt_command_no_executable() {
    echo "" >> $GNUBIN/mycmd
    assertCommandFailOnStatus 127 fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; set GNUBIN '$GNUBIN'; osx_attempt_command mycmd"
}

function test_osx_detect() {
    assertCommandSuccess fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; function uname_cmd; echo Darwin; end; set UNAME uname_cmd; osx_detect"
}

function test_osx_detect_fail() {
    assertCommandFailOnStatus 1 fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; function uname_cmd; echo Linux; end; set UNAME uname_cmd; osx_detect"
}
source $ROOT_LOCATION/tests/bunit/utils/shunit2
