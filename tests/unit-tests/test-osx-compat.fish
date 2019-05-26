#!/usr/bin/env bash
ROOT_LOCATION="$(dirname $0)/../.."

source "$ROOT_LOCATION/tests/bunit/utils/utils.sh"

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

function fish_wrapper(){
    echo "$@" > "${OUTPUT_DIR}/fish_command"
    fish ${OUTPUT_DIR}/fish_command
}

function test_osx_update_path_gnubin_no_exists() {
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set COREUTILS_GNUBIN 'not-a-directory';
    set SED_GNUBIN 'not-a-directory';
    set GREP_GNUBIN 'not-a-directory';
    osx_update_path;
    echo \$PATH"
    assertEquals "$(fish_wrapper "echo \$PATH")" "$(cat $STDOUTF)"
}

function test_osx_update_path() {
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set COREUTILS_GNUBIN '$COREUTILS_GNUBIN';
    set SED_GNUBIN '$SED_GNUBIN';
    set GREP_GNUBIN '$GREP_GNUBIN';
    osx_update_path;
    echo \$PATH"
    assertEquals "$(fish_wrapper "echo $GREP_GNUBIN $SED_GNUBIN $COREUTILS_GNUBIN \$PATH")" "$(cat $STDOUTF)"
}

function test_osx_attempt_command() {
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set COREUTILS_GNUBIN '$COREUTILS_GNUBIN';
    set SED_GNUBIN '$SED_GNUBIN';
    set GREP_GNUBIN '$GREP_GNUBIN';
    osx_attempt_command ls"
}

function test_osx_attempt_command_not_a_command() {
    assertCommandFailOnStatus 127 fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set COREUTILS_GNUBIN '$COREUTILS_GNUBIN';
    set SED_GNUBIN '$SED_GNUBIN';
    set GREP_GNUBIN '$GREP_GNUBIN';
    osx_attempt_command nocmd"
}

function test_osx_attempt_command_on_coreutils_gnubin() {
    cat <<EOF > $COREUTILS_GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $COREUTILS_GNUBIN/mycmd
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set COREUTILS_GNUBIN '$COREUTILS_GNUBIN';
    osx_attempt_command mycmd"
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_osx_attempt_command_on_sed_gnubin() {
    cat <<EOF > $SED_GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $SED_GNUBIN/mycmd
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set SED_GNUBIN '$SED_GNUBIN';
    osx_attempt_command mycmd"
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_osx_attempt_command_on_grep_gnubin() {
    cat <<EOF > $GREP_GNUBIN/mycmd
#!/bin/bash
echo mycommand
EOF
    chmod +x $GREP_GNUBIN/mycmd
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set GREP_GNUBIN '$GREP_GNUBIN';
    osx_attempt_command mycmd"
    assertEquals "mycommand" "$(cat $STDOUTF)"
}

function test_osx_attempt_command_no_executable() {
    echo "" >> $COREUTILS_GNUBIN/mycmd
    assertCommandFailOnStatus 127 fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set COREUTILS_GNUBIN '$COREUTILS_GNUBIN';
    osx_attempt_command mycmd"

    echo "" >> $SED_GNUBIN/mycmd
    assertCommandFailOnStatus 127 fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set SED_GNUBIN '$SED_GNUBIN';
    osx_attempt_command mycmd"

    echo "" >> $GREP_GNUBIN/mycmd
    assertCommandFailOnStatus 127 fish_wrapper "
    source $(dirname $0)/../../lib/osx-compat.fish;
    set GREP_GNUBIN '$GREP_GNUBIN';
    osx_attempt_command mycmd"
}

function test_osx_detect() {
    assertCommandSuccess fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; function uname_cmd; echo Darwin; end; set UNAME uname_cmd; osx_detect"
}

function test_osx_detect_fail() {
    assertCommandFailOnStatus 1 fish_wrapper "source $(dirname $0)/../../lib/osx-compat.fish; function uname_cmd; echo Linux; end; set UNAME uname_cmd; osx_detect"
}

source $ROOT_LOCATION/tests/bunit/utils/shunit2
