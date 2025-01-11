#!/bin/bash

exclude_branches=("master" "main" "release" "stg" "sand" "develop")

function delete_merged_branch() {
  # リモートのデフォルトブランチを取得
  default_branch=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
  echo "default branch: $default_branch"

  # マージ済みのローカルブランチを取得
  merged_branches=$(git branch --merged origin/$default_branch | grep -v '^\*' | grep -vE $(IFS=\|; echo "${exclude_branches[*]}") | xargs)
  echo "merged branches: $merged_branches"

  # マージ済みのローカルブランチを削除
  for branch in $merged_branches; do
    git branch -d $branch
  done
}

delete_merged_branch
