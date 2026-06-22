# Git worktree helpers for interactive zsh sessions.

__gwt_require_git_worktree() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 -- "Not in a git worktree"
    return 1
  fi
}

__gwt_require_fzf() {
  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -- "fzf is required"
    return 1
  fi
}

__gwt_main_worktree() {
  local line

  while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
      print -r -- "${line#worktree }"
      return 0
    fi
  done < <(git worktree list --porcelain)

  return 1
}

__gwt_workspace_root() {
  local main_root="$1"
  print -r -- "$main_root.workspace"
}

__gwt_ensure_workspace_root() {
  local workspace_root="$1"

  if [[ -e "$workspace_root" && ! -d "$workspace_root" ]]; then
    print -u2 -- "Workspace root exists but is not a directory: $workspace_root"
    return 1
  fi

  mkdir -p "$workspace_root"
}

__gwt_prune_empty_parents() {
  local wt_path="$1"
  local stop="$2"
  local dir="${wt_path:h}"

  while [[ "$dir" != "$stop" && "$dir" == "$stop"/* ]]; do
    rmdir "$dir" 2>/dev/null || break
    dir="${dir:h}"
  done
}

__gwt_emit_worktree_row() {
  local mode="$1"
  local current="$2"
  local main="$3"
  local wt_path="$4"
  local branch="$5"
  local state status_output

  [[ -n "$wt_path" ]] || return 0

  case "$mode" in
    remove)
      [[ "$wt_path" != "$main" && "$wt_path" != "$current" ]] || return 0
      state="CLEAN"
      if ! status_output="$(git -C "$wt_path" status --porcelain 2>/dev/null)"; then
        state="DIRTY"
      elif [[ -n "$status_output" ]]; then
        state="DIRTY"
      fi
      print -r -- "$state"$'\t'"$branch"$'\t'"$wt_path"
      ;;
    move)
      state="OTHER"
      [[ "$wt_path" == "$current" ]] && state="CURRENT"
      print -r -- "$state"$'\t'"$branch"$'\t'"$wt_path"
      ;;
  esac
}

__gwt_worktree_rows() {
  local mode="$1"
  local current="$2"
  local main="$3"
  local line wt_path branch

  wt_path=""
  branch="(detached)"

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == worktree\ * ]]; then
      wt_path="${line#worktree }"
      branch="(detached)"
    elif [[ "$line" == branch\ * ]]; then
      branch="${line#branch }"
      branch="${branch#refs/heads/}"
    elif [[ -z "$line" ]]; then
      __gwt_emit_worktree_row "$mode" "$current" "$main" "$wt_path" "$branch"
      wt_path=""
      branch="(detached)"
    fi
  done < <(git worktree list --porcelain)

  __gwt_emit_worktree_row "$mode" "$current" "$main" "$wt_path" "$branch"
}

gwta() {
  if [[ $# -ne 1 ]]; then
    print -u2 -- "Usage: gwta <branch-name>"
    return 2
  fi

  __gwt_require_git_worktree || return

  local branch_name="$1"
  local main_root workspace_root target parent base

  if ! git check-ref-format --branch "$branch_name" >/dev/null 2>&1; then
    print -u2 -- "Invalid branch name: $branch_name"
    return 2
  fi

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    print -u2 -- "Branch already exists: $branch_name"
    return 1
  fi

  if ! main_root="$(__gwt_main_worktree)"; then
    print -u2 -- "Could not find main worktree"
    return 1
  fi

  workspace_root="$(__gwt_workspace_root "$main_root")"
  __gwt_ensure_workspace_root "$workspace_root" || return

  target="$workspace_root/$branch_name"
  if [[ -e "$target" ]]; then
    print -u2 -- "Path already exists: $target"
    return 1
  fi

  print -- "Fetching origin"
  git fetch origin || return

  if ! base="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD)"; then
    print -u2 -- "Could not resolve origin/HEAD"
    return 1
  fi

  parent="${target:h}"
  mkdir -p "$parent" || return

  if ! git worktree add "$target" -b "$branch_name" "$base"; then
    __gwt_prune_empty_parents "$target" "$workspace_root"
    return 1
  fi

  cd "$target" || return
}

gwtr() {
  __gwt_require_git_worktree || return
  __gwt_require_fzf || return

  local current main workspace_root candidates selected line state branch wt_path reply
  local -a dirty_lines

  current="$(git rev-parse --show-toplevel)" || return
  main="$(__gwt_main_worktree)" || return
  workspace_root="$(__gwt_workspace_root "$main")"
  candidates="$(__gwt_worktree_rows remove "$current" "$main" | sort -t $'\t' -k3,3)"

  if [[ -z "$candidates" ]]; then
    print -- "No removable worktrees"
    return 0
  fi

  selected="$(
    print -r -- "$candidates" |
      fzf --multi \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --preview='git -C {3} status --short --branch'
  )" || return 0

  [[ -n "$selected" ]] || return 0

  dirty_lines=()
  for line in ${(f)selected}; do
    IFS=$'\t' read -r state branch wt_path <<< "$line"
    [[ "$state" == "DIRTY" ]] && dirty_lines+=("$branch"$'\t'"$wt_path")
  done

  if (( ${#dirty_lines[@]} > 0 )); then
    print -- "Selected dirty worktrees:"
    for line in "${dirty_lines[@]}"; do
      IFS=$'\t' read -r branch wt_path <<< "$line"
      print -- "  $branch  $wt_path"
    done
    read -r "reply?Remove selected dirty worktrees? [y/N] "
    if [[ "$reply" != [yY] ]]; then
      print -- "Aborted"
      return 1
    fi
  fi

  for line in ${(f)selected}; do
    IFS=$'\t' read -r state branch wt_path <<< "$line"
    print -- "Removing $wt_path"
    if [[ "$state" == "DIRTY" ]]; then
      git worktree remove --force "$wt_path" || return
    else
      git worktree remove "$wt_path" || return
    fi
    __gwt_prune_empty_parents "$wt_path" "$workspace_root"
  done
}

gwtm() {
  __gwt_require_git_worktree || return
  __gwt_require_fzf || return

  local current main candidates selected state branch wt_path

  current="$(git rev-parse --show-toplevel)" || return
  main="$(__gwt_main_worktree)" || return
  candidates="$(__gwt_worktree_rows move "$current" "$main" | sort -t $'\t' -k3,3)"

  if [[ -z "$candidates" ]]; then
    print -u2 -- "Not in a git worktree"
    return 1
  fi

  selected="$(
    print -r -- "$candidates" |
      fzf \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --preview='git -C {3} status --short --branch'
  )" || return 0

  [[ -n "$selected" ]] || return 0

  IFS=$'\t' read -r state branch wt_path <<< "$selected"
  cd "$wt_path" || return
}
