#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKETCHYBAR_DIR="$DOTFILES_DIR/sketchybar"
AEROSPACE_DIR="$DOTFILES_DIR/aerospace"
BORDERS_DIR="$DOTFILES_DIR/borders"
WM_DIR="$DOTFILES_DIR/wm"

if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    BOLD="$(tput bold)"
    DIM="$(tput dim)"
    RESET="$(tput sgr0)"
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
else
    BOLD=""
    DIM=""
    RESET=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
fi

section() {
    printf "\n%s%s%s\n" "$BOLD$BLUE" "$1" "$RESET"
}

info() {
    printf "%s%s%s\n" "$DIM" "$1" "$RESET"
}

success() {
    printf "%s✓%s %s\n" "$GREEN" "$RESET" "$1"
}

warn() {
    printf "%s!%s %s\n" "$YELLOW" "$RESET" "$1"
}

error() {
    printf "%sError:%s %s\n" "$RED" "$RESET" "$1" >&2
}

die() {
    error "$1"
    exit 1
}

backup_path() {
    local target=$1
    local backup="${target}.bak.$(date +%s)"

    warn "Backing up $target -> $backup"
    mv "$target" "$backup"
}

link_path() {
    local source=$1
    local target=$2

    if [ ! -e "$source" ]; then
        die "Missing source: $source"
    fi

    if [ -L "$target" ]; then
        local current_target
        current_target=$(readlink "$target")
        if [ "$current_target" = "$source" ]; then
            success "$target already linked"
            return 0
        fi
        backup_path "$target"
    elif [ -e "$target" ]; then
        backup_path "$target"
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    success "$target linked"
}

compile_helper() {
    local source=$1
    local output=$2
    shift 2

    if [ -x "$output" ]; then
        success "$output already built"
        return 0
    fi

    if ! command -v clang >/dev/null 2>&1; then
        warn "clang not found; leaving $output unbuilt"
        return 0
    fi

    clang "$source" -o "$output" "$@" || warn "Could not build $output"
    if [ -x "$output" ]; then
        success "$output built"
    fi
}

prepare_helpers() {
    section "Helpers"

    compile_helper \
        "$SKETCHYBAR_DIR/helpers/inputsource.c" \
        "$SKETCHYBAR_DIR/helpers/inputsource" \
        -framework Carbon

    compile_helper \
        "$SKETCHYBAR_DIR/helpers/inputsource-watch.c" \
        "$SKETCHYBAR_DIR/helpers/inputsource-watch" \
        -framework Carbon

    compile_helper \
        "$WM_DIR/menubar-autohide.c" \
        "$WM_DIR/menubar-autohide" \
        -framework SkyLight

    chmod +x "$SKETCHYBAR_DIR/sketchybarrc"
    chmod +x "$SKETCHYBAR_DIR/plugins/"*.sh
    chmod +x "$BORDERS_DIR/bordersrc"
}

link_configs() {
    section "Symlinks"
    link_path "$SKETCHYBAR_DIR" "$HOME/.config/sketchybar"
    link_path "$BORDERS_DIR" "$HOME/.config/borders"
    link_path "$AEROSPACE_DIR/aerospace.toml" "$HOME/.aerospace.toml"
    link_path "$WM_DIR" "$HOME/.config/wm"
}

reload_services() {
    section "Reload"

    if command -v brew >/dev/null 2>&1 && brew list sketchybar >/dev/null 2>&1; then
        brew services restart sketchybar
    elif command -v sketchybar >/dev/null 2>&1; then
        sketchybar --reload
    else
        warn "sketchybar not found; install it before using the bar config"
    fi

    if command -v brew >/dev/null 2>&1 && brew list borders >/dev/null 2>&1; then
        brew services restart borders
    elif command -v borders >/dev/null 2>&1; then
        borders
    else
        warn "borders not found; install it before using the focus border config"
    fi

    if command -v aerospace >/dev/null 2>&1; then
        aerospace reload-config || warn "AeroSpace config is linked, but reload-config failed"
    else
        warn "AeroSpace CLI not found; reload it manually after installing AeroSpace"
    fi
}

main() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        die "This installer is macOS-only."
    fi

    section "macOS Desktop Installer"
    info "Repository: $DOTFILES_DIR"
    info "This is intentionally separate from ./install.sh."

    prepare_helpers
    link_configs
    reload_services

    section "Done"
    success "macOS desktop config installed"
}

main "$@"
