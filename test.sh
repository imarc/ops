#!/usr/bin/env bash

source 'cmd.sh'

myprog-happy() {
    cmd-doc "Show a smiley face"
    echo ":)"
}

myprog-args() {
    cmd-doc "Show the supplied args"
    cmd-arg verbose "-v|--verbose" "enable verbose output"

    eval $(cmd-get-input "$@")

    echo $verbose
}

cmd-run myprog "$@"
