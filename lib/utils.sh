#!/bin/sh

declare -A CONFIG_FILES
CONFIG_FILES[bash]="$HOME/.bashrc"
CONFIG_FILES[emacs]="$HOME/.emacs"
CONFIG_FILES[fish]="$HOME/.config/fish/config.fish"
CONFIG_FILES[git]="$HOME/.gitconfig"
CONFIG_FILES[gtk2]="$HOME/.gtkrc-2.0"
CONFIG_FILES[gvim]="$HOME/.gvimrc"
CONFIG_FILES[ideavim]="$HOME/.ideavimrc"
CONFIG_FILES[inputrc]="$HOME/.inputrc"
CONFIG_FILES[mutt]="$HOME/.muttrc"
CONFIG_FILES[screen]="$HOME/.screenrc"
CONFIG_FILES[ssh]="$HOME/.ssh/config"
CONFIG_FILES[tmux]="$HOME/.tmux.conf"
CONFIG_FILES[vim]="$HOME/.vimrc"
CONFIG_FILES[vimperator]="$HOME/.vimperatorrc"
CONFIG_FILES[zsh]="$HOME/.zshrc"

declare -A SOURCE_LINES
SOURCE_LINES[bash]="source \"{}\""
SOURCE_LINES[emacs]="(load-file \"{}\")"
SOURCE_LINES[fish]="source \"{}\""
SOURCE_LINES[git]="[include] path = \"{}\""
SOURCE_LINES[gtk2]="include \"{}\""
SOURCE_LINES[gvim]="source {}"
SOURCE_LINES[ideavim]="source {}"
SOURCE_LINES[inputrc]="\$include {}"
SOURCE_LINES[mutt]="source {}"
SOURCE_LINES[screen]="source {}"
SOURCE_LINES[ssh]="Include {}"
SOURCE_LINES[tmux]="source {}"
SOURCE_LINES[vim]="source {}"
SOURCE_LINES[vimperator]="source {}"
SOURCE_LINES[zsh]="source \"{}\""

CURL=curl
GIT=git
VIM=vim
WGET=wget

NULL_EXCEPTION=11
WRONG_ANSWER=33
NO_FILE_OR_DIRECTORY=2
NOT_A_SYMLINK=44
BROKEN_SYMLINK=45

#######################################
# Check if the argument is null.
#
# Globals:
#   None
# Arguments:
#   argument ($1)    : Argument to check.
# Returns:
#   0                : If argument is not null.
#   NULL_EXCEPTION   : If argument is null.
# Output:
#   None
#######################################
function check_not_null() {
    [ -z "$1" ] && { error "Error: null argument $1"; return $NULL_EXCEPTION; }
    return 0
}

#######################################
# Redirect message to stderr.
#
# Globals:
#   None
# Arguments:
#   msg ($@): Message to print.
# Returns:
#   None
# Output:
#   Message printed to stderr.
#######################################
function echoerr() {
    echo "$@" 1>&2;
}

#######################################
# Print an error message to stderr and exit program.
#
# Globals:
#   None
# Arguments:
#   msg ($@)   : Message to print.
# Returns:
#   1          : The unique exit status printed.
# Output:
#   Message printed to stderr.
#######################################
function die() {
    error $@
    exit 1
}

#######################################
# Print an error message to stderr and exit program with a given status.
#
# Globals:
#   None
# Arguments:
#   status ($1)     : The exit status to use.
#   msg ($2-)       : Message to print.
# Returns:
#   $?              : The $status exit status.
# Output:
#   Message printed to stderr.
#######################################
function die_on_status() {
    status=$1
    shift
    error $@
    exit $status
}

#######################################
# Print an error message to stderr.
#
# Globals:
#   None
# Arguments:
#   msg ($@): Message to print.
# Returns:
#   None
# Output:
#   Message printed to stderr.
#######################################
function error() {
    echoerr -e "\033[0;31m$@\033[0m"
}

#######################################
# Print a warn message to stderr.
#
# Globals:
#   None
# Arguments:
#   msg ($@): Message to print.
# Returns:
#   None
# Output:
#   Message printed to stderr.
#######################################
function warn() {
    # $@: msg (mandatory) - str: Message to print
    echoerr -e "\033[0;33m$@\033[0m"
}

#######################################
# Print an info message to stdout.
#
# Globals:
#   None
# Arguments:
#   msg ($@): Message to print.
# Returns:
#   None
# Output:
#   Message printed to stdout.
#######################################
function info(){
    echo -e "\033[0;36m$@\033[0m"
}

#######################################
# Print escape chars to activate the bold white style.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# Output:
#   Print the bold white escape chars.
#######################################
function bold_white(){
    echo -ne "\033[1;37m"
}

#######################################
# Print escape chars to activate the bold cyan style.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# Output:
#   Print the bold white escape chars.
#######################################
function bold_cyan(){
    echo -ne "\033[1;36m"
}

#######################################
# Print escape chars to activate the bold cyan style.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# Output:
#   Print the bold cyan escape chars.
#######################################
function bold_cyan(){
    echo -ne "\033[1;36m"
}

#######################################
# Print escape chars to activate the bold red style.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# Output:
#   Print the bold red escape chars.
#######################################
function bold_red(){
    echo -ne "\033[1;35m"
}

#######################################
# Print escape char to deactivate any style.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# Output:
#   Print the normal escape chars.
#######################################
function normal(){
    echo -ne "\033[0m"
}

#######################################
# Ask a question and wait to receive an answer from stdin.
# It returns $default_answer if no answer has been received from stdin.
#
# Example of usage:
#
# ask "Would you like the ice cream?" "N"
# Would you like the ice cream? (N/y)> _
#
# Globals:
#   None
# Arguments:
#   question ($1)       : The question to ask.
#   default_answer ($2?) : Possible values: 'Y', 'y', 'N', 'n' (default: 'Y')
# Returns:
#   0                   : If user replied with either 'Y' or 'y'.
#   1                   : If user replied with either 'N' or 'n'.
#   WRONG_ANSWER        : If `default_answer` is not one of the possible values.
# Output:
#   Print the question to ask.
#######################################
function ask(){
    local question=$1
    local default_answer=$2
    check_not_null $question

    if [[ ! -z "$default_answer" ]]
    then
        local answers="Y y N n"
        [[ "$answers" =~ "$default_answer" ]] || { error "The default answer: $default_answer is wrong."; return $WRONG_ANSWER; }
    fi

    local default="Y"
    [[ -z "$default_answer" ]] || default=$(echo "$default_answer" | tr '[:lower:]' '[:upper:]')

    local other="n"
    [[ "$default" == "N" ]] && other="y"

    local prompt=$(info "$question (${default}/${other})> ")

    local res
    read -p "$prompt" res
    res=$(echo "$res" | tr '[:lower:]' '[:upper:]')
    while [[ "$res" != "Y" ]] && [[ "$res" != "N"  ]] && [[ "$res" != "" ]];
    do
        warn "The chosen value is not correct. Type again...\n"
        read -p "$prompt" res
        res=$(echo "$res" | tr '[:lower:]' '[:upper:]')
    done

    [[ "$res" == "" ]] && res="$default"

    [[ "$res" == "Y" ]]
}

#######################################
# Ask a question and wait to receive an answer from stdin between the possible values.
# It returns $default_answer if no answer has been received from stdin.
#
# Example of usage:
#
# choose "Which color do you like?" "Red" "Black" "Yellow" "Red" "Green"
# Which color do you like? (default: Red).
#
# 0) Black
# 1) Yellow
# 2) Red
# 3) Green
#
# Enter a number (default value: Red)>
#
# Globals:
#   None
# Arguments:
#   question ($1)       : The question to ask.
#   default_answer ($2) : The default answer if no input is given
#   values ($3-)        : The possible allowed values.
# Returns:
#   -
# Output:
#   The input specified by the user or the default input.
#######################################
function choose(){
    local question=$1
    local default_answer=$2
    shift 2
    local values=("$@")
    check_not_null $question
    check_not_null $default_answer
    check_not_null $values

    local values_text=""
    for i in "${!values[@]}"
    do
        values_text="$values_text\n$i) ${values[$i]}"
    done

    local prompt=$(info "$question\n$values_text\n\nEnter a number (default value: ${default_answer})> ")

    local res
    read -p "$prompt" res
    local regex='^[0-9]+$'
    while [[ "$res" != "" ]] && ( ! [[ "$res" =~ $regex ]] || [[ "$res" -ge ${#values[@]} ]] || [[ "$res" -lt 0 ]] )
    do
        warn "The chosen value is not correct. Type again...\n"
        read -p "$prompt" res
    done

    if [[ -z "$res" ]]
    then
        echo "$default_answer"
    else
        echo "${values[$res]}"
    fi

}

#######################################
# Check if an array contains a certain value.
#
# Example of usage:
#
# contains_element "Red" "Yellow" "Green" "Red"
#
# Globals:
#   None
# Arguments:
#   match ($1)          : The search string.
#   array ($2-)         : The array elements.
# Returns:
#   0                   : The array contains the element.
#   0                   : The array does not contain the element.
# Output:
#   -
#######################################
function contains_element () {
  local match="$1"
  shift
  local e
  for e in "$@"
  do
      [[ "$e" == "$match" ]] && return 0
  done
  return 1
}

#######################################
# Ask a question and wait to receive an input from stdin.
# It returns $default_input if no input has been received from stdin.
#
# Example of usage:
#
# input "Which city do you like?" "Rome"
# Which city do you like? (default: Rome)> _
#
# Globals:
#   None
# Arguments:
#   question ($1)        : The question to ask.
#   default_input ($2?)  : The default input (Default '').
# Returns:
#   -
# Output:
#   The input specified by the user or the default input.
#######################################
function input(){
    local question=$1
    local default_input=$2
    check_not_null $question

    local prompt=$(info "${question} (default: ${default_input})> ")

    local res=""
    read -p "$prompt" res

    [[ "$res" == "" ]] && res="$default_input"

    echo "$res"
}

#######################################
# Check before overriding a trap for the given signals.
# If trap exists the function will NOT override it.
#
# Globals:
#   None
# Arguments:
#   command ($1)        : The command to invoke for the given signals.
#   sigs ($2-)          : The list of signals (to get the entire list `trap -l`).
# Returns:
#   0                   : Trap created successfully.
#   1                   : If trap exists for the given signals.
# Output:
#   None
#######################################
function check_and_trap() {
    local sigs="${@:2:${#@}}"
    local traps="$(trap -p $sigs)"
    [[ $traps ]] && die "Attempting to overwrite existing $sigs trap: $traps"
    trap $@
}

#######################################
# Check before overriding a trap for the given signals.
# If trap exists the function will warn and override it.
#
# Globals:
#   None
# Arguments:
#   command ($1)        : The command to invoke for the given signals.
#   sigs ($2-)          : The list of signals (to get the entire list `trap -l`).
# Returns:
#   0                   : Trap created/overridden successfully.
# Output:
#   None
#######################################
function check_and_force_trap() {
    local sigs="${@:2:${#@}}"
    local traps="$(trap -p $sigs)"
    [[ $traps ]] && warn "Attempting to overwrite existing $sigs trap: $traps"
    trap $@
}

#######################################
# Apply a string to a file.
# The function is idempotent, so calling this function multiple
# times will apply the string once.
# If $config_file does not exist, the function will create the file and all its
# parent directories (if needed).
#
# Example of usage:
#    apply "source ~/myvimrcfile" ~/.vimrc
#
# Globals:
#   None
# Arguments:
#   string_to_apply ($1) : String to apply.
#   config_file ($2)     : The file in which the string
#                          needs to be applied.
#   apply_at_top ($3?)   : If true puts the string at the top,
#                          otherwise append it (default true).
# Returns:
#   None
# Output:
#   None
#######################################
function apply(){
    local string_to_apply=$1
    local config_file=$2
    local apply_at_top=$3
    check_not_null $string_to_apply
    check_not_null $config_file

    if [ ! -e "$config_file" ]
    then
        local dirp=$(dirname "$config_file")
        mkdir -p $dirp
        touch "$config_file"
    fi

    local putfirst=true
    [ -z "$apply_at_top" ] || putfirst=$apply_at_top

    local original=$(grep -F -x -v "$string_to_apply" "$config_file")
    if $putfirst
    then
        echo -e "$string_to_apply\n$original" > "$config_file"
    else
        echo -e "$original\n$string_to_apply" > "$config_file"
    fi
}

#######################################
# Check if a string is applied to a file.
#
# Globals:
#   None
# Arguments:
#   string_to_apply ($1): String to apply
#   config_file ($2)    : The file in which the string
#                         needs to be applied
# Returns:
#   0                   : If $string_to_apply is matching
#                         a line in $config_file file.
#   1                   : If $string_to_apply is not available
#                         in $config_file file.
#   2                   : If $config_file file does not exist.
# Output:
#   None
#######################################
function is_applied(){
    local string_to_apply=$1
    local config_file=$2
    check_not_null $string_to_apply
    check_not_null $config_file

    grep -q -F -x "$string_to_apply" "$config_file"
}

#######################################
# Unapply a string to a file.
# The function is idempotent, so calling this function multiple
# times will remove the string entirely and if the string does not exist
# it will return successfully.
# If $config_file does not exist, the function will
# return successfully.
#
# Globals:
#   None
# Arguments:
#   string_to_apply ($1): String to apply
#   config_file ($2)    : The file in which the string
#                         needs to be applied
# Returns:
#   None
# Output:
#   None
#######################################
function unapply(){
    local string_to_apply=$1
    local config_file=$2
    check_not_null $string_to_apply
    check_not_null $config_file

    [ ! -e "$config_file" ] && return

    local original=$(grep -F -x -v "$string_to_apply" "$config_file")
    echo -e "$original" > $config_file
}

#######################################
# Simplify the use of the apply() function.
# User can apply a certain config file to a (well known) program without knowing
# about the syntax used to import the config file.
# All available programs are defined in the variable CONFIG_FILES.
#
# The function is idempotent, so calling this function multiple
# times will apply the string once.
# If the program config file does not exist, the function will create the file and all its
# parent directories (if needed).
#
# Example of usage:
#     link vim $HOME/myvimrc
#
# Globals:
#   HOME (RO)                  : The program config files are located in HOME.
# Arguments:
#   program ($1)               : Can be one of the keys in CONFIG_FILES
#   config_file_to_apply ($2)  : The file used to link to the program
#   apply_at_top ($3?)         : If true will put the line
#                                at the top of the file (default true).
# Returns:
#   33                         : If program does not exist
# Output:
#   None
#######################################
function link() {
    local program=$1
    local config_file_to_apply=$2
    local apply_at_top=$3
    check_not_null $program
    check_not_null $config_file_to_apply

    local config_file=${CONFIG_FILES[$program]}
    [ -z "$config_file" ] && { error "The program $program does not exist" ; return 33; }
    local source_line=${SOURCE_LINES[$program]}
    [ -z "$source_line" ] && { error "The program $program does not exist" ; return 33; }

    apply "${source_line/\{\}/$config_file_to_apply}" "$config_file" $apply_at_top
}

#######################################
# Simplify the use of the unapply() function.
# User can unapply a certain config file to a (well known) program without knowing
# about the syntax used to import the config file.
# All available programs are defined in the variable CONFIG_FILES.
#
# The function is idempotent, so calling this function multiple
# times will remove the string entirely and if the string does not exist
# it will return successfully.
# If the program config file does not exist, the function will
# return successfully.
#
# Example of usage:
#     unlink vim $HOME/myvimrc
#
# Globals:
#   HOME (RO)                  : The program config files are located in HOME.
# Arguments:
#   program ($1)               : Can be one of the keys in CONFIG_FILES
#   config_file_to_apply ($2)  : The file used to link to the program
#   apply_at_top ($3)          : If true will put the line
#                                at the top of the file (default true).
# Returns:
#   33                         : If program does not exist
#######################################
function unlink() {
    local program=$1
    local config_file_to_apply=$2
    check_not_null $program
    check_not_null $config_file_to_apply

    local config_file=${CONFIG_FILES[$program]}
    [ -z "$config_file" ] && { error "The program $program does not exist" ; return 33; }
    local source_line=${SOURCE_LINES[$program]}
    [ -z "$source_line" ] && { error "The program $program does not exist" ; return 33; }

    unapply "${source_line/\{\}/$config_file_to_apply}" "$config_file"
}

#######################################
# Symlink the given file to the given destination
# path.
#
# The function is idempotent, so calling this function multiple
# times will link the file once.
#
# The function will fail according to the condition in `check_link` function.
#
# Example of usage:
#    link_to "~/myfile" "~/mysymlink"
#
# Globals:
#  None
# Arguments:
#   file_path ($1)       : The source file path.
#   symlink_path ($2)    : The destination symlink path
#                          (with symlink name included).
# Returns:
#   0                    : Successfully linked.
#   NO_FILE_OR_DIRECTORY : $file_path does not exist.
#   36                   : Symlink exists on a differt source file.
#   NOT_A_SYMLINK        : Symlink is not a symbolic link.
# Output:
#   None
#######################################
function link_to() {
    local file_path=$1
    check_not_null ${file_path}
    local symlink_path=$2
    check_not_null ${symlink_path}

    check_link "${file_path}" "${symlink_path}"
    [[ ! -L ${symlink_path} ]] && ln -s "${file_path}" "${symlink_path}"

    return 0
}

#######################################
# Check if the symlink for the given file is properly installed.
#
# The function will fail if:
# - the symlink is broken
# - the symlink corresponds to a different source file path
#   from $file_path
# - the symlink is not a symbolic link
#
# Example of usage:
#    check_link "~/myfile" "~/mysymlink"
#
# Globals:
#   None
# Arguments:
#   file_path ($1)       : The source file path.
#   symlink_path ($2)    : The destination symlink path
#                          (with symlink name included).
# Returns:
#   0                    : Successfully checked.
#   NO_FILE_OR_DIRECTORY : $file_path does not exist.
#   36                   : Symlink exists on a differt source file.
#   NOT_A_SYMLINK        : Symlink is not a symbolic link.
# Output:
#   None
#######################################
function check_link() {
    local file_path=$1
    check_not_null ${file_path}
    local symlink_path=$2
    check_not_null ${symlink_path}

    [[ ! -e "${file_path}" ]] \
        && { error "The path $file_path does not exist" ; return $NO_FILE_OR_DIRECTORY; }

    [[ -e ${symlink_path} ]] && [[ ! -L ${symlink_path} ]] \
        && { error "The file $symlink_path is not a symlink" ; return $NOT_A_SYMLINK; }

    [[ ! -e ${symlink_path} ]] && [[ -L ${symlink_path} ]] \
        && { error "The file $symlink_path is a broken link" ; return $BROKEN_SYMLINK; }

    if [[ -e ${symlink_path}  ]]
    then
        local file_real_path=$(readlink -f "${file_path}")
        local symlink_real_path=$(readlink -f "${symlink_path}")

        [[ "$symlink_real_path" != "$file_real_path" ]] \
            && { warn "Could not unlink: Symlink ${symlink_path} already exists from source ${symlink_real_path} which is different from $file_real_path"; return 36; }
    fi

    return 0
}

#######################################
# Remove the symlink of the given file to the given destination
# path.
#
# The function will fail according to the condition in `check_link` function.
#
# The function is idempotent, so calling this function multiple
# times will unlink the file once.
#
# Example of usage:
#    unlink_from "~/myfile" "~/mysymlink"
#
# Globals:
#   None
# Arguments:
#   file_path ($1)       : The source file path.
#   symlink_path ($2)    : The destination symlink path
#                          (with symlink name included).
# Returns:
#   0                    : Successfully unlinked.
#   NO_FILE_OR_DIRECTORY : $file_path does not exist.
#   36                   : Symlink exists on a differt source file.
#   NOT_A_SYMLINK        : Symlink is not a symbolic link.
# Output:
#   None
#######################################
function unlink_from() {
    local file_path=$1
    check_not_null ${file_path}
    local symlink_path=$2
    check_not_null ${symlink_path}

    check_link "${file_path}" "${symlink_path}"
    [[ -L ${symlink_path} ]] && rm -f "${symlink_path}"

    return 0
}

#######################################
# Download documents using either `wget` or `curl`.
#
# The function is a portable solution for downloading files
# on any OS systems.
# The default command is `wget` and in case the command fails
# the function falls back to `curl` command.
#
# Example of usage:
#    download "https://www.mywebsite/myfile.tar.gz" "compress.tar.gz"
#
# Globals:
#   WGET (RO)
#   CURL (RO)
# Arguments:
#   url ($1)          : The source URL.
#   filename ($2?)    : Write output to the specified filename instead of the remote filename.
# Returns:
#   -                 : Depends on the backend program used (`wget` or `curl`).
# Output:
#   -                 : Depends on the backend program used (`wget` or `curl`).
#######################################
function download(){
    local url="$1"
    local filename="$2"
    check_not_null "$url"

    if [[ -z $filename ]]
    then
        $WGET "$url" || $CURL -L -J -O "$url"
    else
        $WGET -O "$filename" "$url" || $CURL -L -o "$filename" "$url"
    fi
}

#######################################
# Either install or update a vim plugin in git repository
# providing information about the latest git commit messages.
#
# Example of usage:
#    install_or_update_vim_plugin_git_repo "https://github.com/myname/myplugin" "/path/to/my/repo" "master"
#
# Globals:
#   VIM (RO)
# Arguments:
#   url ($1)          : Git URL
#   plugin_path ($2)  : Location where the plugin
#                       will be installed
#   branch_name ($3?) : Name of the branch to checkout
#                       (If empty "" it defaults to repository's HEAD).
#   quiet ($4?)       : If true, suppress the git logs and
#                       shows the latest three commit message updates only
#                       (Default: true).
# Returns:
#   None
# Output:
#   Logs from git commands.
#######################################
function install_or_update_vim_plugin_git_repo(){
    local url="$1"
    check_not_null "$url"
    local plugin_path="$2"
    check_not_null "$plugin_path"
    local branch_name="$3"
    local quiet="$4"

    install_or_update_git_repo $url "$plugin_path" $branch_name $quiet
    [[ -e "$plugin_path/doc" ]] && \
        $VIM -c "helptags $plugin_path/doc" -c q

    return 0
}


#######################################
# Either install or update a git repository providing information about
# the latest git commit messages.
#
# Example of usage:
#    install_or_update_git_repo "https://github.com/myname/myrepo" "/path/to/my/repo" "master"
#
# Globals:
#   None
# Arguments:
#   url ($1)          : Git URL.
#   dir_path ($2)     : Directory path.
#   branch_name ($3?) : Name of the branch to checkout
#                       (If empty "" it defaults to repository's HEAD).
#   quiet ($4?)       : If true, suppress the git logs and
#                       shows the latest three commit message updates only
#                       (Default: true).
# Returns:
#   None
# Output:
#   Logs from git commands.
#######################################
function install_or_update_git_repo(){
    local url="$1"
    check_not_null "$url"
    local dir_path="$2"
    check_not_null "$dir_path"
    local branch_name="$3"
    local quiet="$4"

    if [[ -d $dir_path ]]; then
        update_git_repo "$dir_path" "$branch_name" $quiet
    else
        install_git_repo "$url" "$dir_path" "$branch_name" $quiet
    fi
}

#######################################
# Install a git repository providing information about
# the latest git commit messages.
#
# Example of usage:
#    install_git_repo "https://github.com/myname/myrepo" "/path/to/my/repo" "master"
#
# Globals:
#   PWD (RO)
#   GIT (RO)
# Arguments:
#   url ($1)          : Git URL.
#   dir_path ($2)     : Directory path.
#   branch_name ($3?) : Name of the branch to checkout
#                       (If empty "" it defaults to repository's HEAD).
#   quiet ($4?)       : If true, suppress the git logs and
#                       shows the latest three commit message updates only
#                       (Default: true).
# Returns:
#   None
# Output:
#   Logs from git commands.
#######################################
function install_git_repo(){
    local url="$1"
    check_not_null "$url"
    local dir_path="$2"
    check_not_null "$dir_path"
    local branch_name="$3"
    local quiet="$4"
    [[ -z $quiet ]] && quiet=true
    local quiet_opt=""
    $quiet && local quiet_opt="--quiet"

    last_pwd="$PWD"
    $GIT clone $quiet_opt "$url" "$dir_path"
    cd "$dir_path"
    $GIT submodule $quiet_opt update --init --recursive
    $GIT --no-pager log -n 3 --no-merges --pretty="tformat:    - %s (%ar)"
    [[ -z $branch_name ]] || $GIT checkout $quiet_opt $branch_name
    cd "$last_pwd"
}

#######################################
# Update a git repository providing information about
# the latest git commit messages.
#
# Example of usage:
#    update_git_repo "/path/to/my/repo" "master"
#
# Globals:
#   PWD (RO)
#   GIT (RO)
# Arguments:
#   dir_path ($1)     : Directory path.
#   branch_name ($2?) : Name of the branch to checkout
#                       (If empty "" it defaults to repository's HEAD).
#   quiet ($3?)       : If true, suppress the git logs and
#                       shows the latest three commit message updates only
#                       (Default: true).
# Returns:
#   None
# Output:
#   Logs from git commands.
#######################################
function update_git_repo(){
    local dir_path="$1"
    check_not_null "$dir_path"
    local branch_name="$2"
    local quiet="$3"
    [[ -z $quiet ]] && quiet=true
    local quiet_opt=""
    $quiet && local quiet_opt="--quiet"

    last_pwd="$PWD"
    cd "$dir_path"
    local last_commit=$($GIT rev-parse HEAD)
    $GIT fetch $quiet_opt --all
    if [[ -z $branch_name ]]
    then
        $GIT reset $quiet_opt --hard @{upstream}
    else
        $GIT reset $quiet_opt --hard origin/$branch_name
    fi
    $GIT submodule $quiet_opt update --init --recursive
    $GIT --no-pager log --no-merges --pretty="tformat:    - %s (%ar)" $last_commit..HEAD
    [[ -z $branch_name ]] || $GIT checkout $quiet_opt $branch_name
    cd "$last_pwd"
}


#######################################
# Simplify the interactive procedure to create configuration file
# or skip it.
# If the configuration file already exists the function will give
# the option to either view, re-use the existing configuration or remove it.
#
# Globals:
#   EDITOR (RO)             : Editor to use for viewing the config file
# Arguments:
#   conf_file_path ($1)     : Path of the config file to manage
#   new_conf_func ($2)      : function which creates the config file
#   apply_conf_func ($3)    : function which apply the config file
#   unapply_conf_func ($4)  : function which unapply the config file
# Returns:
#   None
# Output:
#   Output for choosing the options
#######################################
function setup_configuration() {
    local conf_file_path="$1"
    check_not_null "$conf_file_path"
    local new_conf_func="$2"
    check_not_null "$new_conf_func"
    local apply_conf_func="$3"
    check_not_null "$apply_conf_func"
    local unapply_conf_func="$4"
    check_not_null "$unapply_conf_func"

    chosen="View existing"
    while [[ $chosen == "View existing" ]]
    do
        local answers=("Create new" "Skip")
        local default_answer="Skip"
        [[ -e $conf_file_path ]] && { \
            local answers=("Create new" "View existing" "Remove existing" "Apply existing")
            default_answer="Apply existing"
        }
        info "Setup configuration for ${conf_file_path}"
        local chosen=$(choose "Choose option about configuration" "${default_answer}" "${answers[@]}")

        [[ $chosen == "Skip" ]] && { \
            $unapply_conf_func
            return 0
        }
        [[ $chosen == "View existing" ]] && { \
            editor=${EDITOR:-cat}
            $editor $conf_file_path
        }
        [[ $chosen == "Remove existing" ]] && { \
            $unapply_conf_func
            return 0
        }
        [[ $chosen == "Apply existing" ]] && { \
            $apply_conf_func
            return 0
        }
        [[ $chosen == "Create new" ]] && { \
            $new_conf_func
            $apply_conf_func
            return 0
        }
    done

    return 0
}


#######################################
# Smart backup function for files. If the original file is the same as the
# latest backup, a newer backup will not be created. If there are a number of
# backups greater than num_backups, the oldest backup will be removed.
#
# Globals:
#   NO_FILE_OR_DIRECTORY (RO)
# Arguments:
#   file_path ($1)     : Path of the file to backup
#   num_backups ($2?)  : Max number of allowed backups (Default: 3).
#   quiet ($3?)        : If true, suppress the logs (Default: true).
# Returns:
#   None
# Output:
#   Backup information only when quiet is false
#######################################
function backup() {
    local file_path="$1"
    check_not_null "$file_path"
    local num_backups="${2:-3}"
    local quiet="${3:-true}"

    [[ -d $file_path ]] && die_on_status $NO_FILE_OR_DIRECTORY "$file_path cannot be a directory."
    [[ -f $file_path ]] || die_on_status $NO_FILE_OR_DIRECTORY "$file_path does not exist."

    local backup_name="${file_path}.backup.$(date +"%Y-%m-%d-%H-%M-%S")"
    backup_files=(${file_path}.backup.*)
    if [[ -e ${backup_files[0]} ]]
    then
        # Do not backup if previous backup is the same as the original
        local file_md5sum="$(md5sum ${file_path} | cut -f1 -d ' ')"
        local last_backup="$(ls ${file_path}.backup.* | sort -r | head -n1)"
        local last_backup_md5sum="$(md5sum $last_backup | cut -f1 -d ' ')"
        if [[ "$last_backup_md5sum" != "$file_md5sum" ]]
        then
            $quiet || info "Previous backup has different content. Creating a new one..."
            cp "${file_path}" "${backup_name}"
            $quiet || info "Created backup ${backup_name}"
        fi
    else
        cp "${file_path}" "${backup_name}"
        $quiet || info "Created backup ${backup_name}"
    fi

    # Clean up oldest backups
    for backup_name in $(ls ${file_path}.backup.* | sort | head -n -${num_backups})
    do
        rm -f "${backup_name}"
        $quiet || info "Removed old backup ${backup_name}"
    done

    return 0
}


#######################################
# Simple function to remember to remove file in an idempotent fashion
# (do not fail if file does not exist).
#
# Globals:
#   None
# Arguments:
#   file_paths ($@)     : Path of the file to remove
# Returns:
#   None
# Output:
#   None
#######################################
function delete() {
    check_not_null "$@"
    rm -rf "$@"
    return 0
}
