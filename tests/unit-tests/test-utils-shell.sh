#!/usr/bin/env bash
ROOT_LOCATION="$(dirname $0)/../.."

source "$ROOT_LOCATION/tests/bunit/utils/utils.sh"

source "$ROOT_LOCATION/lib/utils-shell.sh"

# Disable the exiterr
set +e

function oneTimeSetUp(){
    setUpUnitTests
}

function setUp(){
    source "$ROOT_LOCATION/lib/utils-shell.sh"

}

function tearDown(){
    :
}

function test_add_to_path(){
    ORIGIN_PATH=$PATH
    PATH=""
    add_to_path "/usr/mypath/bin"
    PATH_TO_TEST=$PATH
    PATH=$ORIGIN_PATH
    assertEquals $PATH_TO_TEST ":/usr/mypath/bin"
}


function test_add_to_path_already(){
    ORIGIN_PATH=$PATH
    PATH=":/usr/mypath/bin"
    add_to_path "/usr/mypath/bin"
    PATH_TO_TEST=$PATH
    PATH=$ORIGIN_PATH
    assertEquals $PATH_TO_TEST ":/usr/mypath/bin"
}

source $ROOT_LOCATION/tests/bunit/utils/shunit2
