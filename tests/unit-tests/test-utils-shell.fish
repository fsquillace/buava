#!/usr/bin/env bash
ROOT_LOCATION="$(dirname $0)/../.."

source "$ROOT_LOCATION/tests/bunit/utils/utils.sh"

# Disable the exiterr
set +e

function oneTimeSetUp(){
    setUpUnitTests
}

function setUp(){
    :
}

function tearDown(){
    :
}

function fish_wrapper(){
    echo "$@" > "${OUTPUT_DIR}/fish_command"
    fish ${OUTPUT_DIR}/fish_command
}

function test_add_to_path() {
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/utils-shell.fish;
    set -x PATH \"\";
    add_to_path /usr/mypath/bin;
    echo \$PATH;
    "
    assertEquals ". /usr/mypath/bin" "$(cat $STDOUTF)"
}

function test_add_to_path_already() {
    assertCommandSuccess fish_wrapper "
    source $(dirname $0)/../../lib/utils-shell.fish;
    set -x PATH \"/usr/mypath/bin\";
    add_to_path /usr/mypath/bin;
    echo \$PATH;
    "
    assertEquals "/usr/mypath/bin" "$(cat $STDOUTF)"
}

source $ROOT_LOCATION/tests/bunit/utils/shunit2
