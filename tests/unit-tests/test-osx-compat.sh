#!/usr/bin/env bash
source "$(dirname $0)/../utils/utils.sh"

source "$(dirname $0)/../../lib/osx-compat.sh"

# Disable the exiterr
set +e

function oneTimeSetUp(){
    setUpUnitTests
}

function setUp(){
    GNUBIN=$(TMPDIR=/tmp mktemp -d -t buava-test-gnubin.XXXXXXX)
}

function tearDown(){
    rm -rf "$GNUBIN"
    unset GNUBIN
}

function test_buava_update_path_gnubin_no_exists() {
    OLDPATH=$PATH
    OLD_GNUBIN=$GNUBIN
    GNUBIN="/not-a-directory"
    buava_update_path
    assertEquals "$OLDPATH" "$PATH"
    PATH=$OLDPATH
    GNUBIN=$OLD_GNUBIN
}

function test_buava_update_path() {
    OLDPATH=$PATH
    buava_update_path
    assertEquals "$GNUBIN:$OLDPATH" "$PATH"
    PATH=$OLDPATH
}

function test_buava_attempt_command() {
    assertCommandSuccess buava_attempt_command ls
}

function test_buava_attempt_command_not_a_command() {
    assertCommandFailOnStatus 127 buava_attempt_command nocmd
}

function test_buava_attempt_command_on_gnubin() {
    cat <<EOF > $GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $GNUBIN/mycmd
    assertCommandSuccess buava_attempt_command mycmd
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_buava_attempt_command_no_executable() {
    echo "" >> $GNUBIN/mycmd
    assertCommandFailOnStatus 127 buava_attempt_command mycmd
}

source $(dirname $0)/../utils/shunit2
