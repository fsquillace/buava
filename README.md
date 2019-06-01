Buava
=====
The utility library for Bash you always dreamed of.

|Project Status|
|:-----------:|
|[![Build status](https://api.travis-ci.org/fsquillace/buava.png?branch=master)](https://travis-ci.org/fsquillace/buava) |

**Table of Contents**
- [Quickstart](#quickstart)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

Quickstart
==========
Take a look at the script located in [lib directory](lib) like [utils.sh](lib/utils.sh).

Table of buava functions
==================
This table shows a incomplete list of functions available in Buava:

| Function name | Description |
| ------------- | ----------- |
| `check_not_null` | Raise an error if variable is null |
| `echoerr` | Print on stderr |
| `die` | Print a stderr message and terminate with status 1 |
| `die_on_status` | Print a stderr message and terminate with the given status code |
| `error` | Print an error in stderr |
| `warn` | Print a warn in stderr |
| `info` | Print an info in stdout |
| `bold_white` | Change color |
| `bold_cyan` | Change color |
| `bold_cyan` | Change color |
| `bold_red` | Change color |
| `normal` | Change color |
| `ask` | Ask a question to answer Yes/No |
| `choose` | Choose between multiple option |
| `contains_element ` | Check if element is in an array |
| `input` | Take a free form input |
| `check_and_trap` | Before `trap` signal check whether the trap already exists |
| `check_and_force_trap` | Before `trap` signal warn if the trap already exists |
| `apply` | Idempotent apply a message in a file |
| `is_applied` | Check if the message has been applied in a file |
| `unapply` | Idempotent unapply a message in a file |
| `link` | Idempotent link a configuration file to a well-known program (i.e. vim, emacs, and many others)
| `unlink` | Idempotent unlink a configuration file to a well-known program |
| `link_to` | Idempotent symlink from a source to a destination |
| `check_link` | Check symlink
| `unlink_from` | Idempotent unlink a symlink from source to a destination |
| `download` | Flexible and resilient download function |
| `install_or_update_vim_plugin_git_repo` | Idempotent management of vim plugins |
| `install_or_update_git_repo` | Idempotent management of git repos |
| `setup_configuration` | Flexible setup for configurations |
| `backup` | Keep efficiently a number of backups for a given file |
| `delete` | Idempotent delete for files and directories |
| `osx_detect` | True whether the platform is OSX |

Troubleshooting
===============
This section has been left blank intentionally.
It will be filled up as soon as troubles come in!

Contributing
============
You could help improving Buava in the following ways:

- [Reporting Bugs](CONTRIBUTING.md#reporting-bugs)
- [Suggesting Enhancements](CONTRIBUTING.md#suggesting-enhancements)
- [Writing Code](CONTRIBUTING.md#your-first-code-contribution)
