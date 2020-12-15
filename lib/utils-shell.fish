
#######################################
# Adds the specified path to PATH variable.
#
# The function is idempotent, so calling this function multiple
# times will add the path to file just once.
#
# Example of usage:
#    add_to_path "~/bin"
#
# Globals:
#   PATH
# Arguments:
#   path ($1)       : The path to add to PATH
# Returns:
#   0
# Output:
#   None
#######################################
function add_to_path
    set -l path $argv[1]
    if not contains $path $PATH
        set -x PATH $PATH $path
    end
end
