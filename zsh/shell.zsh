# =============================================================================
# Custom Shell Functions & Aliases
# =============================================================================

# -----------------------------------------------------------------------------
# Git 
# -----------------------------------------------------------------------------

# Auto git add, commit, push
push() {
  if [[ -z "$1" ]]; then
    echo "Commit message: "
    read commit_msg
    if [[ -n "$commit_msg" ]]; then
      git add .
      git commit -m "$commit_msg"
      git push origin main
      echo "Commit successfully pushed to origin."
    else
      echo "Commit aborted."
    fi
  else
    git add .
    git commit -m "$1"
    git push origin main
    echo "Commit successfully pushed to origin."
  fi
}

# Auto git add & commit
commit() {
  if [[ -z "$1" ]]; then
    echo "Commit message: "
    read commit_msg
    if [[ -n "$commit_msg" ]]; then
      git add .
      git commit -m "$commit_msg"
      echo "Changes have been successfully committed."
    else
      echo "Commit aborted."
    fi
  else
    git add .
    git commit -m "$1"
    echo "Changes have been successfully committed."
  fi
}

# -----------------------------------------------------------------------------
# Obsidian
# -----------------------------------------------------------------------------

# Open directory as Obsidian vault (auto-registers if needed)
obsidian() {
  local dir="${1:-.}"
  dir="$(cd "$dir" && pwd)"
  local config="$HOME/Library/Application Support/obsidian/obsidian.json"

  # Check if vault is already registered
  if ! jq -e --arg p "$dir" '.vaults | to_entries[] | select(.value.path == $p)' "$config" > /dev/null 2>&1; then
    # Quit Obsidian so it picks up the new config
    osascript -e 'quit app "Obsidian"' 2>/dev/null
    sleep 0.5

    # Generate random 16-char hex ID and register the vault
    local id=$(openssl rand -hex 8)
    local ts=$(date +%s000)
    local tmp=$(mktemp)
    jq --arg id "$id" --arg path "$dir" --arg ts "$ts" \
      '.vaults[$id] = {"path": $path, "ts": ($ts | tonumber)}' "$config" > "$tmp" && mv "$tmp" "$config"
    echo "Registered new vault: $dir"
  fi

  open "obsidian://open?path=$dir"
}

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------

alias ls="lsd"
alias activate="source .venv/bin/activate"
alias logger="git log | nvim -"
alias move_nvim_config='cp -r ~/.config/nvim/* ~/playground/dotfiles/nvim/ && echo "Nvim config files moved to ~/playground/dotfiles/nvim/"'
alias neovim_dir='cd ~/.config/nvim'
