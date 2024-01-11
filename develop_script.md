# 開発用スクリプト


## 全リポジトリのデフォルトブランチをpullする
```
#!/bin/zsh

function pull_default_branch_all_repos() {
  for d in $(find ~/ghq/github.com -depth 2 -type d); do
    cd $d
    echo "---------- $d ----------"

    if [ ! -d .git ]; then
      echo "skip: not a Git-managed directory"
      continue
    fi

    git fetch
    b=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}') # デフォルトブランチを取得する
    git switch $b
    git pull origin $b
  done
}

pull_default_branch_all_repos
```
※ghqのリポジトリ構成を前提としている
