#!/bin/sh
NPMALL_cmdname=${0##*/}

usage()
{
    cat << USAGE >&2
Usage: $NPMALL_cmdname npm_command {...directories}
USAGE
    exit 1
}
if [[ $# -le 1 ]]; then
    echo "Missing arguments"
    usage
fi
npm_command="$1"
shift 1
cwd=$(dirname $0)
real_cwd=$(realpath $cwd)
for directory in "$@"
do
    echo "Executing '$npm_command' in '$directory'"
    cd `realpath $directory`
    npm "$npm_command"
    echo "'$npm_command' in '$directory' finished"
    cd "$real_cwd"
done

command=$1
