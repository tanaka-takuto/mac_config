#!/usr/bin/env bash

ThisFilePath=$(realpath "$0")
TargetPath=$(realpath "$1")

# Get GitHooks Scripts
FileName=$(basename "$ThisFilePath")
DirPath=$(dirname "$ThisFilePath")
GitHookScripts=$(ls $DirPath | grep -v $FileName)

# Check if the target path is provided
if [ -z "$TargetPath" ]; then
    echo "Please provide the target path."
    exit 1
fi
if [ ! -d "$TargetPath" ]; then
    echo "The target path does not exist."
    exit 1
fi
if [ ! -d "$TargetPath/.git/hooks" ]; then
    echo "The target path is not a git repository."
    exit 1
fi

# Copy the git hook scripts to the target path
for GitHookScript in $GitHookScripts; do
    echo "cp \"$DirPath/$GitHookScript\" \"$TargetPath/.git/hooks\""
done

# Set Commit Message template
_filename=${0}
_dirname=$(dirname ${_filename})
echo "git config commit.template ${_dirname}/commit.template.txt"
