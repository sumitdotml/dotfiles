#!/usr/bin/env bash
# GPU-VM-specific tmux wiring.
# Symlinks the VM tmux config + scripts dir from this dotfiles repo into $HOME,
# clones tpm, and installs plugins listed in vm.tmux.conf.
#
# NOT invoked by the main install.sh: run this manually on a given GPU VM after
# cloning the dotfiles repo. Idempotent; so safe to re-run.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMUX_DIR="$DOTFILES_DIR/tmux"

echo "GPU VM tmux setup from $DOTFILES_DIR"

# helpers
backup_or_remove_symlink() {
    local target=$1
    if [ -L "$target" ]; then
        # Existing symlink: remove so we can re-create idempotently.
        rm -f "$target"
    elif [ -e "$target" ]; then
        # Real file/dir: back it up before replacing.
        local backup="${target}.bak.$(date +%s)"
        echo "  📦 Backing up $target -> $backup"
        mv "$target" "$backup"
    fi
}

# 1. symlink ~/.tmux.conf -> dotfiles/tmux/vm.tmux.conf
echo "1️⃣  Linking ~/.tmux.conf -> $TMUX_DIR/vm.tmux.conf"
backup_or_remove_symlink "$HOME/.tmux.conf"
ln -s "$TMUX_DIR/vm.tmux.conf" "$HOME/.tmux.conf"
echo "  ✓"

# 2. symlink ~/.tmux/scripts -> dotfiles/tmux/scripts
echo "2️⃣  Linking ~/.tmux/scripts -> $TMUX_DIR/scripts"
mkdir -p "$HOME/.tmux"
backup_or_remove_symlink "$HOME/.tmux/scripts"
ln -s "$TMUX_DIR/scripts" "$HOME/.tmux/scripts"
echo "  ✓"

# 3. clone tpm if missing
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "3️⃣  Cloning tpm -> $TPM_DIR"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "3️⃣  tpm already present at $TPM_DIR ✓"
fi

# 4. install plugins listed in vm.tmux.conf
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    echo "4️⃣  Installing tmux plugins via tpm"
    # install_plugins needs a tmux server; start one transiently if none exists.
    if ! tmux info >/dev/null 2>&1; then
        tmux new-session -d -s _vmsetup_tpm 'sleep 5'
        "$TPM_DIR/bin/install_plugins" || true
        tmux kill-session -t _vmsetup_tpm 2>/dev/null || true
    else
        "$TPM_DIR/bin/install_plugins"
    fi
fi

echo
echo "Done. To pick up changes in already-running tmux sessions:"
echo "    tmux source ~/.tmux.conf       # or 'prefix + r' inside a pane"
