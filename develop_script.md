# 開発用スクリプト


## 一覧
- [全リポジトリのデフォルトブランチをpullする](develop_script/pull_default_branch_all_repos.zsh)

## デフォルトgitignore
@から始まるフォルダを除外する

```
mkdir -p ~/.config/git
echo "@*/" > ~/.config/git/ignore
git config --global core.excludesfile ~/.config/git/ignore
```
