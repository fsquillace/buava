#!/usr/bin/env bash
ROOT_LOCATION="$(dirname $0)/../.."

source "$ROOT_LOCATION/tests/bunit/utils/utils.sh"
source "$ROOT_LOCATION/lib/osx-compat.sh"

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

function test_osx_update_path_gnubin_no_exists() {
    OLDPATH=$PATH
    OLD_GNUBIN=$GNUBIN
    GNUBIN="/not-a-directory"
    osx_update_path
    assertEquals "$OLDPATH" "$PATH"
    PATH=$OLDPATH
    GNUBIN=$OLD_GNUBIN
}

function test_osx_update_path() {
    OLDPATH=$PATH
    osx_update_path
    assertEquals "$GNUBIN:$OLDPATH" "$PATH"
    PATH=$OLDPATH
}

function test_osx_attempt_command() {
    assertCommandSuccess osx_attempt_command ls
}

function test_osx_attempt_command_not_a_command() {
    assertCommandFailOnStatus 127 osx_attempt_command nocmd
}

function test_osx_attempt_command_on_gnubin() {
    cat <<EOF > $GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $GNUBIN/mycmd
    assertCommandSuccess osx_attempt_command mycmd
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_osx_attempt_command_no_executable() {
    echo "" >> $GNUBIN/mycmd
    assertCommandFailOnStatus 127 osx_attempt_command mycmd
}

function test_osx_attempt_command_on_gnubin_with_spaces() {
    cat <<EOF > $GNUBIN/mycmd
#!/bin/bash
echo "\$1"
EOF
    chmod +x $GNUBIN/mycmd
    assertCommandSuccess osx_attempt_command mycmd this\ is\ one
    assertEquals "this is one" "$(cat $STDOUTF)"
}

function test_osx_detect() {
    uname_cmd(){
        echo 'Darwin'
    }
    UNAME=uname_cmd
    assertCommandSuccess osx_detect
}

function test_osx_detect_fail() {
    uname_cmd(){
        echo 'Linux'
    }
    UNAME=uname_cmd
    assertCommandFailOnStatus 1 osx_detect
}

source $ROOT_LOCATION/tests/bunit/utils/shunit2
