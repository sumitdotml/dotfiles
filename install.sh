#!/usr/bin/env bash
set -eo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIN_NVIM_VERSION="0.12.0"

SYMLINK_COMPONENTS=(nvim tmux ghostty kitty vim)
SELECTED_COMPONENTS=()

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

confirm() {
    local prompt=$1
    local default=${2:-y}
    local suffix
    local answer

    if [ "$default" = "y" ]; then
        suffix="[Y/n]"
    else
        suffix="[y/N]"
    fi

    while true; do
        printf "%s %s " "$prompt" "$suffix"
        read -r answer
        case "$answer" in
            "")
                [ "$default" = "y" ]
                return
                ;;
            y|Y|yes|YES)
                return 0
                ;;
            n|N|no|NO)
                return 1
                ;;
            *)
                warn "Please answer yes or no."
                ;;
        esac
    done
}

component_label() {
    case "$1" in
        deps) echo "Dependencies: Neovim >= ${MIN_NVIM_VERSION}, tmux, git, tree-sitter CLI" ;;
        nvim) echo "Symlink Neovim config" ;;
        ghostty) echo "Symlink Ghostty config" ;;
        tmux) echo "Symlink tmux config" ;;
        catppuccin) echo "tmux Catppuccin theme" ;;
        kitty) echo "Symlink Kitty config" ;;
        vim) echo "Symlink Vim config + install vim-plug" ;;
        *) echo "$1" ;;
    esac
}

select_components() {
    local component

    section "Choose Components"

    if confirm "Check/install command-line dependencies?" "y"; then
        SELECTED_COMPONENTS+=(deps)
    fi

    if confirm "Set up config symlinks from this repo?" "y"; then
        info "This includes Neovim, tmux, Ghostty, Kitty, and Vim. zsh and cc are not linked by this installer."
        for component in "${SYMLINK_COMPONENTS[@]}"; do
            if confirm "$(component_label "$component")?" "y"; then
                SELECTED_COMPONENTS+=("$component")
            fi
        done
    fi

    if confirm "Set up tmux Catppuccin theme?" "y"; then
        SELECTED_COMPONENTS+=(catppuccin)
    fi

    if [ "${#SELECTED_COMPONENTS[@]}" -eq 0 ]; then
        die "No components selected."
    fi
}

print_plan() {
    local component

    section "Install Plan"
    for component in "${SELECTED_COMPONENTS[@]}"; do
        printf "  %s-%s %s\n" "$GREEN" "$RESET" "$(component_label "$component")"
    done
}

version_ge() {
    local current=${1#v}
    local required=${2#v}
    local c_major=0 c_minor=0 c_patch=0
    local r_major=0 r_minor=0 r_patch=0

    current=${current%%-*}
    required=${required%%-*}

    IFS=. read -r c_major c_minor c_patch <<EOF
$current
EOF
    IFS=. read -r r_major r_minor r_patch <<EOF
$required
EOF

    c_major=${c_major:-0}
    c_minor=${c_minor:-0}
    c_patch=${c_patch:-0}
    r_major=${r_major:-0}
    r_minor=${r_minor:-0}
    r_patch=${r_patch:-0}

    if [ "$c_major" -gt "$r_major" ]; then return 0; fi
    if [ "$c_major" -lt "$r_major" ]; then return 1; fi
    if [ "$c_minor" -gt "$r_minor" ]; then return 0; fi
    if [ "$c_minor" -lt "$r_minor" ]; then return 1; fi
    [ "$c_patch" -ge "$r_patch" ]
}

get_nvim_version() {
    local line
    line=$(nvim --version 2>/dev/null | head -n 1 || true)
    if [[ "$line" =~ v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        printf "%s.%s.%s\n" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    fi
}

load_homebrew_shellenv() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

detect_package_manager() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        load_homebrew_shellenv
        if command -v brew >/dev/null 2>&1; then
            echo "brew"
        elif command -v port >/dev/null 2>&1; then
            echo "port"
        else
            echo ""
        fi
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo ""
    fi
}

install_homebrew_for_tmux() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_system_package() {
    local package=$1
    local manager
    manager=$(detect_package_manager)

    case "$manager" in
        brew)
            load_homebrew_shellenv
            if brew list "$package" >/dev/null 2>&1; then
                brew upgrade "$package"
            else
                brew install "$package"
            fi
            ;;
        port)
            sudo port selfupdate
            sudo port install "$package"
            ;;
        apt)
            sudo apt-get update
            sudo apt-get install -y "$package"
            ;;
        dnf)
            sudo dnf install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        pacman)
            sudo pacman -Sy --noconfirm "$package"
            ;;
        *)
            die "No supported package manager found. Please install $package manually."
            ;;
    esac
}

install_official_neovim_release() {
    local os
    local arch
    local asset
    local url
    local tmpdir
    local extracted_dir

    if [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        os="linux"
    else
        die "Unsupported OS for official Neovim install: $OSTYPE"
    fi

    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        *)
            die "Unsupported arch for official Neovim install: $(uname -m)"
            ;;
    esac

    asset="nvim-${os}-${arch}.tar.gz"
    extracted_dir="nvim-${os}-${arch}"
    url="https://github.com/neovim/neovim/releases/latest/download/${asset}"
    tmpdir=$(mktemp -d)

    info "Downloading $url..."
    curl -fsSL -o "$tmpdir/$asset" "$url"
    tar -xzf "$tmpdir/$asset" -C "$tmpdir"

    sudo rm -rf /opt/nvim
    sudo mkdir -p /opt
    sudo mv "$tmpdir/$extracted_dir" /opt/nvim
    sudo mkdir -p /usr/local/bin
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -rf "$tmpdir"

    if ! command -v nvim >/dev/null 2>&1; then
        die "Neovim was installed to /opt/nvim, but /usr/local/bin/nvim is not on PATH."
    fi

    success "Neovim official release installed"
}

active_neovim_is_homebrew() {
    local nvim_path
    local brew_prefix

    if ! command -v nvim >/dev/null 2>&1; then
        return 1
    fi

    if ! command -v brew >/dev/null 2>&1; then
        return 1
    fi

    nvim_path=$(command -v nvim)
    brew_prefix=$(brew --prefix 2>/dev/null || true)
    [ -n "$brew_prefix" ] &&
        [[ "$nvim_path" == "$brew_prefix"/bin/nvim ]] &&
        brew list neovim >/dev/null 2>&1
}

upgrade_neovim_with_package_manager() {
    local manager
    manager=$(detect_package_manager)

    case "$manager" in
        brew)
            if active_neovim_is_homebrew; then
                confirm "Upgrade Neovim using Homebrew?" "y" || return 1
                install_system_package "neovim"
                return 0
            fi
            ;;
    esac

    return 1
}

uninstall_homebrew_neovim_before_official_install() {
    if ! active_neovim_is_homebrew; then
        return 0
    fi

    warn "Homebrew Neovim is still first on PATH. The official install will not be active unless the Homebrew package is removed."
    confirm "Uninstall Homebrew Neovim before installing the official release?" "y" || return 1
    brew uninstall neovim
}

install_neovim_with_version_check() {
    local current_version=""

    if command -v nvim >/dev/null 2>&1; then
        current_version=$(get_nvim_version || true)
        if [ -n "$current_version" ]; then
            info "Current Neovim version: v$current_version"
            info "Required Neovim version: >= v$MIN_NVIM_VERSION"

            if version_ge "$current_version" "$MIN_NVIM_VERSION"; then
                success "Neovim v$current_version meets requirements"
                return 0
            fi

            warn "Neovim v$current_version is too old for this branch."
            warn "Use the <= 0.11 branch instead, or install Neovim >= v$MIN_NVIM_VERSION."
        else
            warn "Could not determine the installed Neovim version."
        fi
    else
        info "No existing Neovim installation found."
    fi

    if upgrade_neovim_with_package_manager; then
        current_version=$(get_nvim_version || true)
        if [ -n "$current_version" ] && version_ge "$current_version" "$MIN_NVIM_VERSION"; then
            success "Neovim upgraded successfully (v$current_version)"
            return 0
        fi
        warn "Package-manager upgrade did not make Neovim >= v$MIN_NVIM_VERSION active on PATH."
    fi

    uninstall_homebrew_neovim_before_official_install || return 0
    confirm "Install Neovim from the official GitHub release archive?" "y" || return 0
    install_official_neovim_release

    if ! command -v nvim >/dev/null 2>&1; then
        die "Failed to install Neovim. Please install it manually."
    fi

    current_version=$(get_nvim_version || true)
    if [ -z "$current_version" ]; then
        die "Neovim installed, but its version could not be detected."
    fi

    if ! version_ge "$current_version" "$MIN_NVIM_VERSION"; then
        die "Installed Neovim v$current_version is still below v$MIN_NVIM_VERSION. This branch expects newer tree-sitter behavior."
    fi

    success "Neovim installed successfully (v$current_version)"
}

install_tmux_dependency() {
    local manager

    if command -v tmux >/dev/null 2>&1; then
        success "tmux already installed"
        return 0
    fi

    manager=$(detect_package_manager)
    if [ -z "$manager" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            confirm "tmux not found, and Homebrew/MacPorts are not installed. Install Homebrew and then tmux?" "n" || {
                warn "Install tmux manually, then rerun this script if needed."
                return 0
            }
            install_homebrew_for_tmux
            manager=$(detect_package_manager)
        else
            warn "tmux is not installed, and no supported package manager was detected."
            warn "Install tmux manually, then rerun this script if needed."
            return 0
        fi
    fi

    confirm "tmux not found. Install tmux using $manager?" "y" || return 0

    install_system_package "tmux"

    if ! command -v tmux >/dev/null 2>&1; then
        die "Failed to install tmux. Please install it manually."
    fi

    success "tmux installed"
}

install_git_dependency() {
    local manager

    if command -v git >/dev/null 2>&1; then
        success "git already installed"
        return 0
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        confirm "git not found. Install Apple's Xcode Command Line Tools?" "y" || return 0
        xcode-select --install || true
        warn "If the Command Line Tools installer opened, finish it and rerun this script."
        return 0
    fi

    manager=$(detect_package_manager)
    if [ -z "$manager" ]; then
        warn "git is not installed, and no supported package manager was detected."
        warn "Install git manually, then rerun this script if needed."
        return 0
    fi

    confirm "git not found. Install git using $manager?" "y" || return 0
    install_system_package "git"

    if ! command -v git >/dev/null 2>&1; then
        die "Failed to install git. Please install it manually."
    fi

    success "git installed"
}

install_tree_sitter_cli() {
    if command -v tree-sitter >/dev/null 2>&1; then
        success "tree-sitter CLI already installed"
        return 0
    fi

    confirm "tree-sitter CLI not found. Install it from the official GitHub release binary?" "y" || return 0

    local os
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        os="linux"
    else
        die "Unsupported OS for tree-sitter install: $OSTYPE"
    fi

    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) die "Unsupported arch: $(uname -m)" ;;
    esac

    local asset="tree-sitter-${os}-${arch}.gz"
    local url="https://github.com/tree-sitter/tree-sitter/releases/latest/download/${asset}"
    local tmpdir
    tmpdir=$(mktemp -d)

    info "Downloading $url..."
    curl -fsSL -o "$tmpdir/tree-sitter.gz" "$url"
    gunzip "$tmpdir/tree-sitter.gz"
    chmod +x "$tmpdir/tree-sitter"
    sudo mkdir -p /usr/local/bin
    sudo mv "$tmpdir/tree-sitter" /usr/local/bin/tree-sitter
    rm -rf "$tmpdir"

    if ! command -v tree-sitter >/dev/null 2>&1; then
        die "Failed to install tree-sitter CLI. Neovim parsers may not auto-install."
    fi

    success "tree-sitter CLI installed"
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

install_deps() {
    section "Dependencies"
    install_neovim_with_version_check
    install_tmux_dependency
    install_git_dependency
    install_tree_sitter_cli
}

install_nvim_config() {
    section "Neovim"
    link_path "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
}

install_ghostty_config() {
    section "Ghostty"
    local source="$DOTFILES_DIR/ghostty/config"
    local target

    if [[ "$OSTYPE" == "darwin"* ]]; then
        target="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
    else
        target="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
    fi

    link_path "$source" "$target"
}

install_tmux_config() {
    section "tmux"
    link_path "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
}

install_catppuccin_theme() {
    section "tmux Catppuccin"
    local theme_dir="$HOME/.config/tmux/plugins/catppuccin/tmux"

    if [ ! -d "$theme_dir" ]; then
        mkdir -p "$HOME/.config/tmux/plugins/catppuccin"
        git clone -b v2.1.2 https://github.com/catppuccin/tmux.git "$theme_dir"
    else
        success "Catppuccin theme already exists"
    fi
}

install_kitty_config() {
    section "Kitty"
    link_path "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
}

install_vim_config() {
    section "Vim"
    local vim_dir="$DOTFILES_DIR/vim"

    link_path "$vim_dir/vimrc" "$HOME/.vimrc"
    link_path "$vim_dir/coc-settings.json" "$HOME/.vim/coc-settings.json"
    link_path "$vim_dir/colors/kanagawa.vim" "$HOME/.vim/colors/kanagawa.vim"

    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        info "Installing vim-plug..."
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        success "vim-plug installed"
    else
        success "vim-plug already installed"
    fi
}

run_component() {
    case "$1" in
        deps) install_deps ;;
        nvim) install_nvim_config ;;
        ghostty) install_ghostty_config ;;
        tmux) install_tmux_config ;;
        catppuccin) install_catppuccin_theme ;;
        kitty) install_kitty_config ;;
        vim) install_vim_config ;;
        *) die "Unknown component '$1'" ;;
    esac
}

main() {
    local component

    if [ "$#" -gt 0 ]; then
        die "This installer is interactive. Run ./install.sh without flags."
    fi

    if [ ! -t 0 ]; then
        die "This installer needs an interactive terminal."
    fi

    section "Dotfiles Installer"
    info "Repository: $DOTFILES_DIR"

    select_components
    print_plan

    confirm "Proceed with this plan?" "y" || die "Installation cancelled."

    for component in "${SELECTED_COMPONENTS[@]}"; do
        run_component "$component"
    done

    section "Done"
    success "Installation complete"
    info "Suggested next steps:"
    info "1. Restart your terminal"
    info "2. Run: tmux source ~/.tmux.conf"
    info "3. Launch nvim and let it install plugins"
    info "4. Launch vim and run :PlugInstall if you installed the Vim config"
}

main "$@"
