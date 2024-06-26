#!/bin/zsh

function pull_default_branch_all_repos() {
  # ghqのディレクトリを再帰的に検索
  for d in $(find ~/ghq/github.com -depth 2 -type d); do
    cd $d
    echo "---------- $d ----------"

    # git対象外のディレクトリはスキップ
    if [ ! -d .git ]; then
      echo "skip: not a Git-managed directory"
      continue
    fi

    # ローカルの変更がある場合はスタッシュする
    git diff --exit-code > /dev/null
    if [ $? -eq 1 ]; then
      stash_message="$(date '+%Y-%m-%d') on $(git symbolic-ref --short HEAD)"
      git stash -u -m "$stash_message"
    else
      echo "skip: no local changes"
    fi

    # デフォルトブランチを取得
    git fetch
    b=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')

    # デフォルトブランチに切り替えて最新にする
    git switch $b
    git pull origin $b

    # マージ済みのブランチを削除
    git branch --merged origin/$b | grep -v '^\*|master|main|stg|sand|develop' | xargs git branch -d
  done
}

pull_default_branch_all_repos