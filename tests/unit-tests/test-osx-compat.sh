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
    COREUTILS_GNUBIN=$(TMPDIR=/tmp mktemp -d -t osx-test-gnubin.XXXXXXX)
    SED_GNUBIN=$(TMPDIR=/tmp mktemp -d -t osx-test-gnubin.XXXXXXX)
    GREP_GNUBIN=$(TMPDIR=/tmp mktemp -d -t osx-test-gnubin.XXXXXXX)
}

function tearDown(){
    rm -rf "$COREUTILS_GNUBIN"
    unset COREUTILS_GNUBIN

    rm -rf "$GREP_GNUBIN"
    unset GREP_GNUBIN

    rm -rf "$SED_GNUBIN"
    unset SED_GNUBIN
}

function test_osx_update_path_gnubin_no_exists() {
    OLDPATH=$PATH
    OLD_COREUTILS_GNUBIN=$COREUTILS_GNUBIN
    OLD_GREP_GNUBIN=$GREP_GNUBIN
    OLD_SED_GNUBIN=$SED_GNUBIN

    COREUTILS_GNUBIN="/not-a-directory"
    GREP_GNUBIN="/not-a-directory"
    SED_GNUBIN="/not-a-directory"

    osx_update_path

    assertEquals "$OLDPATH" "$PATH"

    PATH=$OLDPATH
    COREUTILS_GNUBIN=$OLD_COREUTILS_GNUBIN
    GREP_GNUBIN=$OLD_GREP_GNUBIN
    SED_GNUBIN=$OLD_SED_GNUBIN
}

function test_osx_update_path() {
    OLDPATH=$PATH

    osx_update_path

    assertEquals "$SED_GNUBIN:$GREP_GNUBIN:$COREUTILS_GNUBIN:$OLDPATH" "$PATH"

    PATH=$OLDPATH
}

function test_osx_attempt_command() {
    assertCommandSuccess osx_attempt_command ls
}

function test_osx_attempt_command_not_a_command() {
    assertCommandFailOnStatus 127 osx_attempt_command nocmd
}

function test_osx_attempt_command_on_coreutils_gnubin() {
    cat <<EOF > $COREUTILS_GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $COREUTILS_GNUBIN/mycmd
    assertCommandSuccess osx_attempt_command mycmd
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_osx_attempt_command_on_grep_gnubin() {
    cat <<EOF > $GREP_GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $GREP_GNUBIN/mycmd
    assertCommandSuccess osx_attempt_command mycmd
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_osx_attempt_command_on_sed_gnubin() {
    cat <<EOF > $SED_GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $SED_GNUBIN/mycmd
    assertCommandSuccess osx_attempt_command mycmd
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_osx_attempt_command_no_executable() {
    echo "" >> $COREUTILS_GNUBIN/mycmd
    assertCommandFailOnStatus 127 osx_attempt_command mycmd
    rm $COREUTILS_GNUBIN/mycmd

    echo "" >> $SED_GNUBIN/mycmd
    assertCommandFailOnStatus 127 osx_attempt_command mycmd
    rm $SED_GNUBIN/mycmd

    echo "" >> $GREP_GNUBIN/mycmd
    assertCommandFailOnStatus 127 osx_attempt_command mycmd
    rm $GREP_GNUBIN/mycmd
}

function test_osx_attempt_command_on_gnubin_with_spaces() {
    cat <<EOF > $COREUTILS_GNUBIN/mycmd
#!/bin/bash
echo "\$1"
EOF
    chmod +x $COREUTILS_GNUBIN/mycmd

    cat <<EOF > $SED_GNUBIN/mycmd2
#!/bin/bash
echo "\$1"
EOF
    chmod +x $SED_GNUBIN/mycmd2

    cat <<EOF > $GREP_GNUBIN/mycmd3
#!/bin/bash
echo "\$1"
EOF
    chmod +x $GREP_GNUBIN/mycmd3

    assertCommandSuccess osx_attempt_command mycmd this\ is\ one
    assertEquals "this is one" "$(cat $STDOUTF)"

    assertCommandSuccess osx_attempt_command mycmd2 this\ is\ one
    assertEquals "this is one" "$(cat $STDOUTF)"

    assertCommandSuccess osx_attempt_command mycmd3 this\ is\ one
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
