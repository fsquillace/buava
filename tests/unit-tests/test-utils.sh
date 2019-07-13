#!/usr/bin/env bash
ROOT_LOCATION="$(dirname $0)/../.."

source "$ROOT_LOCATION/tests/bunit/utils/utils.sh"

# Do NOT remove the next line as you do not want to remove the original
# HOME directory!
unset HOME
export HOME=$(TMPDIR=/tmp mktemp -d -t buava-user-home.XXXXXXX)

source "$ROOT_LOCATION/lib/utils.sh"

# Disable the exiterr
set +e

FILEPATH=/tmp/file_buava_test

function oneTimeSetUp(){
    setUpUnitTests
}

function setUp(){
    source "$ROOT_LOCATION/lib/utils.sh"

    touch $FILEPATH
    # Recreate HOME for the new test
    mkdir -p $HOME/symlinks
}

function tearDown(){
    rm $FILEPATH
    [[ -d $HOME ]] && rm -rf $HOME
}

function test_check_not_null(){
    assertCommandFailOnStatus 11 check_not_null "" ""
    assertCommandSuccess check_not_null "bla" ""
}

function test_echoerr(){
    assertCommandSuccess echoerr "Test"
    assertEquals "Test" "$(cat $STDERRF)"
}

function test_error(){
    assertCommandSuccess error "Test"
    local expected=$(echo -e "\033[1;31mTest\033[0m")
    assertEquals "$expected" "$(cat $STDERRF)"
}

function test_warn(){
    assertCommandSuccess warn "Test"
    local expected=$(echo -e "\033[1;33mTest\033[0m")
    assertEquals "$expected" "$(cat $STDERRF)"
}

function test_info(){
    assertCommandSuccess info "Test"
    local expected=$(echo -e "\033[1;36mTest\033[0m")
    assertEquals "$expected" "$(cat $STDOUTF)"
}

function test_die(){
    assertCommandFail die "Test"
    local expected=$(echo -e "\033[1;31mTest\033[0m")
    assertEquals "$expected" "$(cat $STDERRF)"
}

function test_die_on_status(){
    assertCommandFailOnStatus 222 die_on_status 222 "Test"
    local expected=$(echo -e "\033[1;31mTest\033[0m")
    assertEquals "$expected" "$(cat $STDERRF)"
}

function test_ask_null_question(){
    assertCommandFailOnStatus 11 ask "" "Y"
}

function test_ask(){
    echo "Y" | ask "Test"
    assertEquals 0 $?
    echo "y" | ask "Test"
    assertEquals 0 $?
    echo "N" | ask "Test"
    assertEquals 1 $?
    echo "n" | ask "Test"
    assertEquals 1 $?
    echo -e "NoAnswer\nn" | ask "Test" 2> /dev/null
    assertEquals 1 $?
    echo -e "\n" | ask "Test"
    assertEquals 0 $?
    echo -e "\n" | ask "Test" "N"
    assertEquals 1 $?
    echo -e "asdf\n\n" | ask "Test" "N" 2> /dev/null
    assertEquals 1 $?
}

function test_ask_wrong_default_answer() {
    echo "Y" | ask "Test" G &> /dev/null
    assertEquals 33 $?
}

function test_choose_null_question(){
    assertCommandFailOnStatus 11 choose "" "Red" "Yellow" "Green"
}

function test_choose_null_default_answer(){
    assertCommandFailOnStatus 11 choose "???" "" "Yellow" "Green"
}

function test_choose_null_values(){
    assertCommandFailOnStatus 11 choose "???" "Red" ""
}

function test_choose(){
    local res=$(echo "" | choose "Which color?" "Red" "Yellow" "Green")
    assertEquals "Red" "$res"
    local res=$(echo "0" | choose "Which color?" "Red" "Yellow" "Green")
    assertEquals "Yellow" "$res"
    local res=$(echo -e "NoColor\n0" | choose "Which color?" "Red" "Yellow" "Green" 2> /dev/null)
    assertEquals "Yellow" "$res"
    local res=$(echo -e "NoColor" | choose "Which color?" "Red" "Yellow" "Green" 2> /dev/null)
    assertEquals "Red" "$res"
    local res=$(echo -e "-1\n1" | choose "Which color?" "Red" "Yellow" "Green" 2> /dev/null)
    assertEquals "Green" "$res"
    local res=$(echo -e "9\n1" | choose "Which color?" "Red" "Yellow" "Green" 2> /dev/null)
    assertEquals "Green" "$res"
    local res=$(echo -e "notnumber\n1" | choose "Which color?" "Red" "Yellow" "Green" 2> /dev/null)
    assertEquals "Green" "$res"
}

function test_contains_element(){
    local array=("apple" "banana" "peach" "ki wi")
    assertCommandSuccess contains_element "peach" "${array[@]}"
    assertCommandSuccess contains_element "ki wi" "${array[@]}"

    assertCommandFail contains_element "orange" "${array[@]}"
}

function test_input_null_question(){
    assertCommandFailOnStatus 11 input "" "Red"
}

function test_input(){
    local res=$(echo "Red" | input "Which color?" "Yellow")
    assertEquals "Red" "$res"
    local res=$(echo -e "\n" | input "Which color?" "Yellow")
    assertEquals "Yellow" "$res"
    local res=$(echo -e "\n" | input "Which color?")
    assertEquals "" "$res"
}

function test_check_and_trap_fail() {
    trap echo EXIT
    trap ls QUIT
    assertCommandFailOnStatus 1 check_and_trap 'pwd' EXIT QUIT
}

function test_check_and_trap() {
    trap - EXIT QUIT
    assertCommandSuccess check_and_trap 'echo' EXIT QUIT
}

function test_check_and_force_trap_fail() {
    trap echo EXIT
    trap ls QUIT
    assertCommandSuccess check_and_force_trap 'echo' EXIT QUIT
}

function test_check_and_force_trap() {
    trap - EXIT QUIT
    assertCommandSuccess check_and_force_trap 'echo' EXIT QUIT
}


function test_apply_null_line(){
    assertCommandFailOnStatus 11 apply "" "$FILEPATH"
}

function test_apply_null_filepath(){
    assertCommandFailOnStatus 11 apply "source blah" ""
}

function test_apply_at_top(){
    echo -e "myoldstring\nmynewstring" > $FILEPATH
    assertCommandSuccess apply "mystring" $FILEPATH
    assertEquals "$(echo -e "mystring\nmyoldstring\nmynewstring")" "$(cat $FILEPATH)"

    echo -e "myoldstring\nmynewstring" > $FILEPATH
    assertCommandSuccess apply "mystring" $FILEPATH true
    assertEquals "$(echo -e "mystring\nmyoldstring\nmynewstring")" "$(cat $FILEPATH)"
}

function test_apply_file_with_spaces(){
    local filepath="/tmp/myfile with spaces"
    echo -e "myoldstring" > "$filepath"
    assertCommandSuccess apply "mystring" "$filepath"
    assertEquals "$(echo -e "mystring\nmyoldstring")" "$(cat "$filepath")"
}

function test_apply_at_bottom(){
    echo -e "myoldstring\nmynewstring" > $FILEPATH
    assertCommandSuccess apply "mystring" $FILEPATH false
    assertEquals "$(echo -e "myoldstring\nmynewstring\nmystring")" "$(cat $FILEPATH)"
}

function test_apply_create_directory(){
    local filepath=/tmp/mydir/myfile
    assertCommandSuccess apply "mystring" $filepath false
    assertEquals "$(echo -e "\nmystring")" "$(cat $filepath)"

    rm $filepath
    rmdir $(dirname $filepath)
}

function test_is_applied_null_line(){
    assertCommandFailOnStatus 11 is_applied "" "$FILEPATH"
}

function test_is_applied_null_filepath(){
    assertCommandFailOnStatus 11 is_applied "source blah" ""
}

function test_is_not_applied(){
    assertCommandFailOnStatus 1 is_applied "mystring" $FILEPATH
}

function test_is_applied_file_not_exist(){
    assertCommandFailOnStatus 2 is_applied "mystring" /tmp/file-does-not-exist
}

function test_is_applied(){
    echo -e "myoldstring\nmystring\nmynewstring" > $FILEPATH
    assertCommandSuccess is_applied "mystring" $FILEPATH
}

function test_unapply_null_line(){
    assertCommandFailOnStatus 11 unapply "" "$FILEPATH"
}

function test_unapply_null_filepath(){
    assertCommandFailOnStatus 11 unapply "source blah" ""
}

function test_unapply_on_empty_file(){
    assertCommandSuccess unapply "mystring" $FILEPATH
    assertEquals "" "$(cat $FILEPATH)"
}

function test_unapply_on_non_existing_file(){
    assertCommandSuccess unapply "mystring" "${FILEPATH}_no_existing"
    [ ! -e "${FILEPATH}_no_existing" ]
    assertEquals 0 $?
}

function test_unapply_with_match(){
    echo -e "myoldstring\nmystring\nmynewstring" > $FILEPATH
    assertCommandSuccess unapply "mystring" $FILEPATH
    assertEquals "$(echo -e "myoldstring\nmynewstring")" "$(cat $FILEPATH)"
}
function test_unapply_with_a_complex_match(){
    echo -e "myoldstring\nmy(s.*t\\\[ri[ng\nmynewstring" > $FILEPATH
    assertCommandSuccess unapply "my(s.*t\[ri[ng" $FILEPATH
    assertEquals "$(echo -e "myoldstring\nmynewstring")" "$(cat $FILEPATH)"
}

function test_unapply_without_match(){
    echo -e "myoldstring\nmystring\nmynewstring" > $FILEPATH
    assertCommandSuccess unapply "mystring2" $FILEPATH
    assertEquals "$(echo -e "myoldstring\nmystring\nmynewstring")" "$(cat $FILEPATH)"
}

function test_link_null_program(){
    assertCommandFailOnStatus 11 link "" "$FILEPATH"
}

function test_link_null_filepath(){
    assertCommandFailOnStatus 11 link "vim" ""
}

function test_link_at_top(){
    echo -e "myoldstring" > $HOME/.vimrc
    assertCommandSuccess link "vim" $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH\nmyoldstring")" "$(cat $HOME/.vimrc)"

    echo -e "myoldstring" > $HOME/.vimrc
    assertCommandSuccess link "vim" $FILEPATH true
    assertEquals "$(echo -e "source $FILEPATH\nmyoldstring")" "$(cat $HOME/.vimrc)"
}

function test_link_at_bottom(){
    echo -e "myoldstring" > $HOME/.vimrc
    assertCommandSuccess link "vim" $FILEPATH false
    assertEquals "$(echo -e "myoldstring\nsource $FILEPATH")" "$(cat $HOME/.vimrc)"
}

function test_link_not_a_program(){
    assertCommandFailOnStatus 33 link "notvim" $FILEPATH
}

function test_link_file_with_spaces(){
    local filepath="/tmp/myfile with spaces"
    touch $HOME/.bashrc
    echo 'p="pwd"' > "$filepath"
    assertCommandSuccess link "bash" "$filepath"
    assertEquals "$(echo -e "source \"$filepath\"")" "$(cat $HOME/.bashrc)"
    assertEquals "pwd" "$(bash -c "source $HOME/.bashrc; echo \$p")"
}

function test_link_all_programs(){
    assertCommandSuccess link bash $FILEPATH
    assertEquals "$(echo -e "source \"$FILEPATH\"")" "$(cat $HOME/.bashrc)"
    assertCommandSuccess unlink bash $FILEPATH
    assertEquals "" "$(cat $HOME/.bashrc)"

    assertCommandSuccess link emacs $FILEPATH
    assertEquals "$(echo -e "(load-file \"$FILEPATH\")")" "$(cat $HOME/.emacs)"
    assertCommandSuccess unlink emacs $FILEPATH
    assertEquals "" "$(cat $HOME/.emacs)"

    assertCommandSuccess link fish $FILEPATH
    assertEquals "$(echo -e "source \"$FILEPATH\"")" "$(cat $HOME/.config/fish/config.fish)"
    assertCommandSuccess unlink fish $FILEPATH
    assertEquals "" "$(cat $HOME/.config/fish/config.fish)"

    assertCommandSuccess link git $FILEPATH
    assertEquals "$(echo -e "[include] path = \"$FILEPATH\"")" "$(cat $HOME/.gitconfig)"
    assertCommandSuccess unlink git $FILEPATH
    assertEquals "" "$(cat $HOME/.gitconfig)"

    assertCommandSuccess link gtk2 $FILEPATH
    assertEquals "$(echo -e "include \"$FILEPATH\"")" "$(cat $HOME/.gtkrc-2.0)"
    assertCommandSuccess unlink gtk2 $FILEPATH
    assertEquals "" "$(cat $HOME/.gtkrc-2.0)"

    assertCommandSuccess link "gvim" $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH")" "$(cat $HOME/.gvimrc)"
    assertCommandSuccess unlink gvim $FILEPATH
    assertEquals "" "$(cat $HOME/.gvimrc)"

    assertCommandSuccess link "ideavim" $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH")" "$(cat $HOME/.ideavimrc)"
    assertCommandSuccess unlink ideavim $FILEPATH
    assertEquals "" "$(cat $HOME/.ideavimrc)"

    assertCommandSuccess link inputrc $FILEPATH
    assertEquals "$(echo -e "\$include $FILEPATH")" "$(cat $HOME/.inputrc)"
    assertCommandSuccess unlink inputrc $FILEPATH
    assertEquals "" "$(cat $HOME/.inputrc)"

    assertCommandSuccess link mutt $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH")" "$(cat $HOME/.muttrc)"
    assertCommandSuccess unlink mutt $FILEPATH
    assertEquals "" "$(cat $HOME/.muttrc)"

    assertCommandSuccess link screen $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH")" "$(cat $HOME/.screenrc)"
    assertCommandSuccess unlink screen $FILEPATH
    assertEquals "" "$(cat $HOME/.screenrc)"

    assertCommandSuccess link ssh $FILEPATH
    assertEquals "$(echo -e "Include $FILEPATH")" "$(cat $HOME/.ssh/config)"
    assertCommandSuccess unlink ssh $FILEPATH
    assertEquals "" "$(cat $HOME/.ssh/config)"

    assertCommandSuccess link tmux $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH")" "$(cat $HOME/.tmux.conf)"
    assertCommandSuccess unlink tmux $FILEPATH
    assertEquals "" "$(cat $HOME/.tmux.conf)"

    assertCommandSuccess link "vim" $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH")" "$(cat $HOME/.vimrc)"
    assertCommandSuccess unlink vim $FILEPATH
    assertEquals "" "$(cat $HOME/.vimrc)"

    assertCommandSuccess link vimperator $FILEPATH
    assertEquals "$(echo -e "source $FILEPATH")" "$(cat $HOME/.vimperatorrc)"
    assertCommandSuccess unlink vimperator $FILEPATH
    assertEquals "" "$(cat $HOME/.vimperatorrc)"

    assertCommandSuccess link zsh $FILEPATH
    assertEquals "$(echo -e "source \"$FILEPATH\"")" "$(cat $HOME/.zshrc)"
    assertCommandSuccess unlink zsh $FILEPATH
    assertEquals "" "$(cat $HOME/.zshrc)"
}

function test_unlink_null_program(){
    assertCommandFailOnStatus 11 unlink "" "$FILEPATH"
}

function test_unlink_null_filepath(){
    assertCommandFailOnStatus 11 unlink "vim" ""
}

function test_unlink(){
    echo -e "myoldstring\nsource $FILEPATH" > $HOME/.vimrc
    assertCommandSuccess unlink "vim" $FILEPATH
    assertEquals "$(echo -e "myoldstring")" "$(cat $HOME/.vimrc)"
}

function test_unlink_not_a_program(){
    assertCommandFailOnStatus 33 unlink "notvim" $FILEPATH
}

function test_link_to_null_file_path(){
    assertCommandFailOnStatus 11 link_to "" "symlink"
}

function test_link_to_null_symlink_path(){
    assertCommandFailOnStatus 11 link_to "file" ""
}

function test_link_to_not_existing_file_path(){
    assertCommandFailOnStatus 2 link_to "not-exist" "symlink"
}

function test_link_to(){
    echo "Content" > $HOME/binary
    assertCommandSuccess link_to "$HOME/binary" "$HOME/symlinks/binary"
    assertEquals "Content" "$(cat $HOME/symlinks/binary)"
}

function test_link_to_different_name(){
    echo "Content" > $HOME/binary
    assertCommandSuccess link_to "$HOME/binary" "$HOME/symlinks/binary2"
    assertEquals "Content" "$(cat $HOME/symlinks/binary2)"
}

function test_link_to_not_a_symlink(){
    echo "Old content" > $HOME/symlinks/binary
    echo "Content" > $HOME/binary
    assertCommandFailOnStatus 44 link_to "$HOME/binary" "$HOME/symlinks/binary"
}

function test_link_to_already_existing_symlink(){
    echo "Content" > $HOME/binary
    echo "Old content" > $HOME/binary2
    ln -s $HOME/binary2 $HOME/symlinks/binary
    assertCommandFailOnStatus 36 link_to "$HOME/binary" "$HOME/symlinks/binary"
    assertEquals "Old content" "$(cat $HOME/symlinks/binary)"
}

function test_link_to_already_existing_broken_symlink(){
    echo "Content" > $HOME/binary
    echo "Old content" > $HOME/binary2
    ln -s $HOME/binary2 $HOME/symlinks/binary
    rm $HOME/binary2
    assertCommandFailOnStatus 45 link_to "$HOME/binary" "$HOME/symlinks/binary"
}

function test_link_to_already_existing_same_symlink(){
    echo "Content" > $HOME/binary
    ln -s $HOME/binary $HOME/symlinks/binary
    assertCommandSuccess link_to "$HOME/binary" "$HOME/symlinks/binary"
    assertEquals "Content" "$(cat $HOME/symlinks/binary)"
}

function test_check_link_null_file_path(){
    assertCommandFailOnStatus 11 check_link "" "symlink"
}

function test_check_link_null_symlink_path(){
    assertCommandFailOnStatus 11 check_link "file" ""
}

function test_check_link_not_existing_file_path(){
    assertCommandFailOnStatus 2 check_link "not-exist" "symlink"
}

function test_check_link(){
    echo "Content" > $HOME/binary
    assertCommandSuccess check_link "$HOME/binary" "$HOME/symlinks/binary"
}

function test_check_link_different_name(){
    echo "Content" > $HOME/binary
    assertCommandSuccess check_link "$HOME/binary" "$HOME/symlinks/binary2"
}

function test_check_link_not_a_symlink(){
    echo "Old content" > $HOME/symlinks/binary
    echo "Content" > $HOME/binary
    assertCommandFailOnStatus 44 check_link "$HOME/binary" "$HOME/symlinks/binary"
}

function test_check_link_already_existing_symlink(){
    echo "Content" > $HOME/binary
    echo "Old content" > $HOME/binary2
    ln -s $HOME/binary2 $HOME/symlinks/binary
    assertCommandFailOnStatus 36 check_link "$HOME/binary" "$HOME/symlinks/binary"
}

function test_check_link_already_existing_broken_symlink(){
    echo "Content" > $HOME/binary
    echo "Old content" > $HOME/binary2
    ln -s $HOME/binary2 $HOME/symlinks/binary
    rm $HOME/binary2
    assertCommandFailOnStatus 45 check_link "$HOME/binary" "$HOME/symlinks/binary"
}

function test_check_link_to_already_existing_same_symlink(){
    echo "Content" > $HOME/binary
    ln -s $HOME/binary $HOME/symlinks/binary
    assertCommandSuccess check_link "$HOME/binary" "$HOME/symlinks/binary"
    assertEquals "Content" "$(cat $HOME/symlinks/binary)"
}

function test_unlink_from_null_file_path(){
    assertCommandFailOnStatus 11 unlink_from "" "symlink"
}

function test_unlink_from_null_symlink_path(){
    assertCommandFailOnStatus 11 unlink_from "file" ""
}

function test_unlink_from_not_existing_file_path(){
    assertCommandFailOnStatus 2 unlink_from "not-exist" "symlink"
}

function test_unlink_from(){
    echo "Content" > $HOME/binary
    ln -s $HOME/binary $HOME/symlinks
    [[ -L "$HOME/symlinks/binary" ]]
    assertEquals 0 $?
    assertCommandSuccess unlink_from "$HOME/binary" "$HOME/symlinks/binary"
    [[ ! -L "$HOME/symlinks/binary" ]]
    assertEquals 0 $?
}

function test_unlink_from_different_name(){
    echo "Content" > $HOME/binary
    ln -s $HOME/binary $HOME/symlinks/binary2
    [[ -L "$HOME/symlinks/binary2" ]]
    assertEquals 0 $?
    assertCommandSuccess unlink_from "$HOME/binary" "$HOME/symlinks/binary2"
    [[ ! -L "$HOME/symlinks/binary2" ]]
    assertEquals 0 $?
}

function test_unlink_from_not_a_symlink(){
    echo "Old content" > $HOME/symlinks/binary
    echo "Content" > $HOME/binary
    assertCommandFailOnStatus 44 unlink_from "$HOME/binary" "$HOME/symlinks/binary"
}

function test_unlink_from_symlink(){
    echo "Content" > $HOME/binary
    echo "Old content" > $HOME/binary2
    ln -s $HOME/binary2 $HOME/symlinks/binary
    assertCommandFailOnStatus 36 unlink_from "$HOME/binary" "$HOME/symlinks/binary"
    assertEquals "Old content" "$(cat $HOME/symlinks/binary)"
}

function test_unlink_from_source_as_symlink(){
    echo "Content" > $HOME/source-binary
    ln -s $HOME/source-binary $HOME/binary
    ln -s $HOME/binary $HOME/symlinks/binary
    [[ -L "$HOME/symlinks/binary" ]]
    assertEquals 0 $?
    assertCommandSuccess unlink_from "$HOME/binary" "$HOME/symlinks/binary"
    [[ ! -L "$HOME/symlinks/binary" ]]
    assertEquals 0 $?
}

function test_unlink_from_broken_link(){
    echo "Content" > $HOME/binary
    echo "Old content" > $HOME/binary2
    ln -s $HOME/binary2 $HOME/symlinks/binary
    rm $HOME/binary2
    assertCommandFailOnStatus 45 unlink_from "$HOME/binary" "$HOME/symlinks/binary"
}

function test_unlink_from_different_source_files(){
    echo "Content" > $HOME/binary
    echo "Content2" > $HOME/binary2
    ln -s $HOME/binary2 $HOME/symlinks/binary

    [[ -L "$HOME/symlinks/binary" ]]
    assertEquals 0 $?
    assertCommandFailOnStatus 36 unlink_from "$HOME/binary" "$HOME/symlinks/binary"
    [[ -L "$HOME/symlinks/binary" ]]
    assertEquals 0 $?
}

function test_download_null_url(){
    assertCommandFailOnStatus 11 download ""
}

function test_download(){
    true_fn() {
        echo "$@"
        return 0
    }
    false_fn() {
        return 1
    }
    WGET=true_fn
    CURL=false_fn
    assertCommandSuccess download "http://sdf.com"
    assertEquals "http://sdf.com" "$(cat $STDOUTF)"
    assertCommandSuccess download "http://sdf.com" "myfile"
    assertEquals "-O myfile http://sdf.com" "$(cat $STDOUTF)"

    WGET=false_fn
    CURL=true_fn
    assertCommandSuccess download "http://sdf.com"
    assertEquals "-L -J -O http://sdf.com" "$(cat $STDOUTF)"
    assertCommandSuccess download "http://sdf.com" "myfile"
    assertEquals "-L -o myfile http://sdf.com" "$(cat $STDOUTF)"

    WGET=false_fn
    CURL=false_fn
    assertCommandFail download "http://sdf.com"
    assertEquals "" "$(cat $STDOUTF)"
    assertCommandFail download "http://sdf.com" "myfile"
    assertEquals "" "$(cat $STDOUTF)"
}

function test_install_or_update_vim_plugin_git_repo_null_arguments(){
    assertCommandFailOnStatus 11 install_or_update_vim_plugin_git_repo
    assertCommandFailOnStatus 11 install_or_update_vim_plugin_git_repo http://
}

function test_install_or_update_vim_plugin_git_repo_create_quiet(){
    install_or_update_git_repo() {
        echo "install_or_update_git_repo $@"
        mkdir -p "$2"
        return 0
    }

    assertCommandSuccess install_or_update_vim_plugin_git_repo "http://myrepo" "$HOME/myplugindir" "master" quiet

    assertEquals "$(echo -e "install_or_update_git_repo http://myrepo $HOME/myplugindir master quiet")" "$(cat $STDOUTF)"
}

function test_install_or_update_vim_plugin_git_repo_create_quiet_with_doc(){
    install_or_update_git_repo() {
        echo "install_or_update_git_repo $@"
        mkdir -p "$2/doc"
        return 0
    }
    vim_cmd() {
        echo "vim $@"
    }
    VIM=vim_cmd

    assertCommandSuccess install_or_update_vim_plugin_git_repo "http://myrepo" "$HOME/myplugindir" "master" quiet

    assertEquals "$(echo -e "install_or_update_git_repo http://myrepo $HOME/myplugindir master quiet\nvim -c helptags $HOME/myplugindir/doc -c q")" "$(cat $STDOUTF)"
}

function test_install_or_update_git_repo_null_arguments(){
    assertCommandFailOnStatus 11 install_or_update_git_repo
    assertCommandFailOnStatus 11 install_or_update_git_repo "http://myrepo"
}

function test_install_git_repo_null_arguments(){
    assertCommandFailOnStatus 11 install_git_repo
    assertCommandFailOnStatus 11 install_git_repo "http://myrepo"
}

function test_update_git_repo_null_arguments(){
    assertCommandFailOnStatus 11 update_git_repo
}

function test_install_or_update_git_repo_create_quiet(){
    git_cmd() {
        [[ $1 == "clone" ]] && mkdir -p "${@: -1}"
        echo git $@
        return 0
    }
    GIT=git_cmd
    assertCommandSuccess install_or_update_git_repo "http://myrepo" "$HOME/mydir" "master"
    assertEquals "$(echo -e "git clone --quiet http://myrepo $HOME/mydir\ngit submodule --quiet update --init --recursive\ngit --no-pager log -n 3 --no-merges --pretty=tformat: - %s (%ar)\ngit checkout --quiet master")" "$(cat $STDOUTF)"
}

function test_install_or_update_git_repo_create_quiet_no_branch(){
    git_cmd() {
        [[ $1 == "clone" ]] && mkdir -p "${@: -1}"
        echo git $@
        return 0
    }
    GIT=git_cmd
    assertCommandSuccess install_or_update_git_repo "http://myrepo" "$HOME/mydir"
    assertEquals "$(echo -e "git clone --quiet http://myrepo $HOME/mydir\ngit submodule --quiet update --init --recursive\ngit --no-pager log -n 3 --no-merges --pretty=tformat: - %s (%ar)")" "$(cat $STDOUTF)"
}

function test_install_or_update_git_repo_create(){
    git_cmd() {
        [[ $1 == "clone" ]] && mkdir -p "${@: -1}"
        echo git $@
        return 0
    }
    GIT=git_cmd
    assertCommandSuccess install_or_update_git_repo "http://myrepo" "$HOME/mydir" "master" false
    assertEquals "$(echo -e "git clone http://myrepo $HOME/mydir\ngit submodule update --init --recursive\ngit --no-pager log -n 3 --no-merges --pretty=tformat: - %s (%ar)\ngit checkout master")" "$(cat $STDOUTF)"
}

function test_install_or_update_git_repo_update_quiet(){
    git_cmd() {
        echo git $@
        return 0
    }
    GIT=git_cmd
    mkdir -p "$HOME/mydir"
    assertCommandSuccess install_or_update_git_repo "http://myrepo" "$HOME/mydir" "master"
    assertEquals "$(echo -e "git fetch --quiet --all\ngit reset --quiet --hard origin/master\ngit submodule --quiet update --init --recursive\ngit --no-pager log --no-merges --pretty=tformat: - %s (%ar) git rev-parse HEAD..HEAD\ngit checkout --quiet master")" "$(cat $STDOUTF)"
}

function test_install_or_update_git_repo_update_quiet_no_branch(){
    git_cmd() {
        echo git $@
        return 0
    }
    GIT=git_cmd
    mkdir -p "$HOME/mydir"
    assertCommandSuccess install_or_update_git_repo "http://myrepo" "$HOME/mydir"
    assertEquals "$(echo -e "git fetch --quiet --all\ngit reset --quiet --hard @{upstream}\ngit submodule --quiet update --init --recursive\ngit --no-pager log --no-merges --pretty=tformat: - %s (%ar) git rev-parse HEAD..HEAD")" "$(cat $STDOUTF)"
}

function test_install_or_update_git_repo_update(){
    git_cmd() {
        echo git $@
        return 0
    }
    GIT=git_cmd
    mkdir -p "$HOME/mydir"
    assertCommandSuccess install_or_update_git_repo "http://myrepo" "$HOME/mydir" "master" false
    assertEquals "$(echo -e "git fetch --all\ngit reset --hard origin/master\ngit submodule update --init --recursive\ngit --no-pager log --no-merges --pretty=tformat: - %s (%ar) git rev-parse HEAD..HEAD\ngit checkout master")" "$(cat $STDOUTF)"
}

function test_setup_configuration_null_arg(){
    assertCommandFailOnStatus 11 setup_configuration
    assertCommandFailOnStatus 11 setup_configuration "file_path"
    assertCommandFailOnStatus 11 setup_configuration "file_path" "new_conf"
    assertCommandFailOnStatus 11 setup_configuration "file_path" "new_conf" \
        "apply_conf"
}

function test_setup_configuration(){
    local conf_file_path="$HOME/myconffile"
    new_conf(){
        echo "new_conf"
    }
    apply_conf(){
        echo "apply_conf"
    }
    unapply_conf(){
        echo "unapply_conf"
    }

    view_conf(){
        echo "view_conf"
    }

    EDITOR=view_conf

    echo "1" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    grep -q "unapply_conf" $STDOUTF
    assertEquals 0 $?
    assertEquals "unapply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo -e "\n" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "unapply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo -e "1" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "unapply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo "0" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "$(echo -e "new_conf\napply_conf")" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo -e "2\n\n" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "unapply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    touch $conf_file_path

    echo -e "\n" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "apply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo -e "2" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "unapply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo "0" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "$(echo -e "new_conf\napply_conf")" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo "3" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "apply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo -e "1\n\n" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "$(echo -e "view_conf\napply_conf")" "$(cat $STDOUTF | grep -v "Setup configuration for")"

    echo "4\n3" | assertCommandSuccess setup_configuration $conf_file_path \
        new_conf apply_conf unapply_conf
    assertEquals "apply_conf" "$(cat $STDOUTF | grep -v "Setup configuration for")"
}

test_backup_no_file_path() {
    assertCommandFailOnStatus 11 backup
}

test_backup_not_existing_file_path() {
    assertCommandFailOnStatus 2 backup "not_a_file"
}

test_backup_is_a_directory() {
    mkdir -p $HOME/mydirectory
    assertCommandFailOnStatus 2 backup $HOME/mydirectory
}

test_backup_not_already_existing_backups() {
    touch $HOME/original_file
    assertCommandSuccess backup $HOME/original_file
    assertEquals "1" "$(ls $HOME/original_file.backup.* | wc -l)"
}

test_backup_no_backup_allowed() {
    touch $HOME/original_file
    assertCommandSuccess backup $HOME/original_file
    echo "new stuff" > $HOME/original_file
    assertCommandSuccess backup $HOME/original_file 0
    local backup_files=($HOME/original_file.backup.*)
    [[ ! -e ${backup_files[0]} ]]
    assertEquals 0 $?
}

test_backup_clean_up_old_backups() {
    touch $HOME/original_file
    touch $HOME/original_file.backup.{1,2,3,4,5,6,7}
    assertCommandSuccess backup $HOME/original_file
    assertEquals "$(ls $HOME/original_file.backup.*)" "$(echo -e "$HOME/original_file.backup.5\n$HOME/original_file.backup.6\n$HOME/original_file.backup.7")"
    assertCommandSuccess backup $HOME/original_file 2
    assertEquals "$(ls $HOME/original_file.backup.*)" "$(echo -e "$HOME/original_file.backup.6\n$HOME/original_file.backup.7")"
}

test_backup_original_with_different_content() {
    touch $HOME/original_file
    assertCommandSuccess backup $HOME/original_file

    assertEquals "1" "$(ls $HOME/original_file.backup.* | wc -l)"

    sleep 2

    echo "new content" > $HOME/original_file
    assertCommandSuccess backup $HOME/original_file

    assertEquals "2" "$(ls $HOME/original_file.backup.* | wc -l)"
    assertEquals "$(cat $HOME/original_file.backup.*)" "new content"

}

test_delete_no_file_path() {
    assertCommandFailOnStatus 11 delete
}

test_delete_file() {
    touch $HOME/myfile
    assertCommandSuccess delete $HOME/myfile

    [[ ! -e $HOME/myfile ]]
    assertEquals "0" $?
}

test_delete_multiple_files() {
    touch $HOME/myfile
    touch $HOME/myfile2
    touch "$HOME/myfile with spaces"
    assertCommandSuccess delete $HOME/myfile $HOME/myfile2 "$HOME/myfile with spaces"

    cat $STDERRF

    [[ ! -e $HOME/myfile ]]
    assertEquals "0" $?

    [[ ! -e $HOME/myfile2 ]]
    assertEquals "0" $?

    [[ ! -e "$HOME/myfile with spaces" ]]
    assertEquals "0" $?
}

test_delete_directory() {
    mkdir $HOME/mydir
    assertCommandSuccess delete $HOME/mydir

    [[ ! -e $HOME/mydir ]]
    assertEquals "0" $?
}

source $ROOT_LOCATION/tests/bunit/utils/shunit2
