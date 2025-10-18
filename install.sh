#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------
# Version Comparison Function
# --------------------------
version_compare() {
    local version1=$1
    local version2=$2
    
    # Remove 'v' prefix if present
    version1=${version1#v}
    version2=${version2#v}
    
    # Use sort -V to compare versions
    if printf '%s\n%s\n' "$version1" "$version2" | sort -V -C; then
        return 0  # version1 <= version2
    else
        return 1  # version1 > version2
    fi
}

# --------------------------
# Neovim Installation with Version Check
# --------------------------
install_neovim_with_version_check() {
    local min_version="0.11.0"
    
    if command -v nvim &> /dev/null; then
        echo "Found existing neovim installation, checking version..."
        
        # Get current version
        local current_version=$(nvim --version 2>/dev/null | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        
        if [ -z "$current_version" ]; then
            echo "⚠️ Could not determine neovim version, proceeding with reinstallation..."
        else
            echo "Current neovim version: $current_version"
            echo "Required minimum version: v$min_version"
            
            # Compare versions (check if current >= minimum)
            if version_compare "$min_version" "${current_version#v}"; then
                echo "✓ Neovim version $current_version meets requirements (>= v$min_version)"
                echo "✓ Skipping neovim installation"
                return 0
            else
                echo "⚠️ Neovim version $current_version is below required v$min_version"
                echo "🔄 Uninstalling old neovim and installing latest version..."
                
                # Uninstall existing neovim
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    if command -v brew &> /dev/null; then
                        brew uninstall neovim 2>/dev/null || true
                    fi
                else
                    if command -v apt-get &> /dev/null; then
                        sudo apt-get remove -y neovim 2>/dev/null || true
                    elif command -v dnf &> /dev/null; then
                        sudo dnf remove -y neovim 2>/dev/null || true
                    elif command -v yum &> /dev/null; then
                        sudo yum remove -y neovim 2>/dev/null || true
                    elif command -v pacman &> /dev/null; then
                        sudo pacman -R --noconfirm neovim 2>/dev/null || true
                    fi
                fi
                echo "✓ Old neovim uninstalled"
            fi
        fi
    else
        echo "No existing neovim installation found"
    fi
    
    # Install neovim
    echo "📦 Installing latest neovim..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install neovim
    else
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y neovim
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y neovim
        elif command -v yum &> /dev/null; then
            sudo yum install -y neovim
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy --noconfirm neovim
        else
            echo "Unsupported package manager. Please install neovim manually."
            exit 1
        fi
    fi
    
    # Verify installation
    if command -v nvim &> /dev/null; then
        local new_version=$(nvim --version 2>/dev/null | head -1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        echo "✓ Neovim installed successfully (version: ${new_version:-'unknown'})"
    else
        echo "❌ Failed to install neovim. Please install it manually."
        exit 1
    fi
}

# --------------------------
# Dependency Management
# --------------------------
install_dependency() {
    local command=$1
    local package=$2
    
    if ! command -v "$command" &> /dev/null; then
        echo "Installing $package..."
        
        # Detect package manager
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if ! command -v brew &> /dev/null; then
                echo "Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install "$package"
        else
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y "$package"
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y "$package"
            elif command -v yum &> /dev/null; then
                sudo yum install -y "$package"
            elif command -v pacman &> /dev/null; then
                sudo pacman -Sy --noconfirm "$package"
            else
                echo "Unsupported package manager. Please install $package manually."
                exit 1
            fi
        fi
        
        if ! command -v "$command" &> /dev/null; then
            echo "Failed to install $package. Please install it manually."
            exit 1
        fi
        echo "✓ $package installed"
    else
        echo "✓ $package already installed"
    fi
}

# --------------------------
# Backup Functions
# --------------------------
backup_file() {
    local file=$1
    if [ -e "$file" ]; then
        local backup="${file}.bak.$(date +%s)"
        echo "Backing up $file to $backup"
        mv "$file" "$backup"
    fi
}

backup_dir() {
    local dir=$1
    if [ -d "$dir" ]; then
        local backup="${dir}.bak.$(date +%s)"
        echo "Backing up directory $dir to $backup"
        mv "$dir" "$backup"
    fi
}

# --------------------------
# Main Installation
# --------------------------
echo "🚀 Starting dotfiles installation"

# Check and install dependencies
echo "🔍 Checking dependencies..."
install_neovim_with_version_check
install_dependency "tmux" "tmux"
install_dependency "git" "git"

# Neovim configuration
echo "📝 Installing Neovim config..."
NVIM_TARGET="$HOME/.config/nvim"
backup_dir "$NVIM_TARGET"
mkdir -p "$HOME/.config"
cp -r "$DOTFILES_DIR/nvim" "$NVIM_TARGET"
echo "✓ Neovim configuration installed"

# Ghostty configuration
echo "👻 Installing Ghostty config..."
GHOSTTY_SRC="$DOTFILES_DIR/ghostty/config"

if [[ "$OSTYPE" == "darwin"* ]]; then
    GHOSTTY_TARGET="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
else
    GHOSTTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
    GHOSTTY_TARGET="$GHOSTTY_CONFIG_DIR/config"
fi

mkdir -p "$(dirname "$GHOSTTY_TARGET")"
backup_file "$GHOSTTY_TARGET"
cp "$GHOSTTY_SRC" "$GHOSTTY_TARGET"
echo "✓ Ghostty config installed to $GHOSTTY_TARGET"

# Tmux configuration
echo "🎨 Installing tmux config..."
TMUX_CONF_SRC="$DOTFILES_DIR/tmux/.tmux.conf"
TMUX_CONF_TARGET="$HOME/.tmux.conf"
backup_file "$TMUX_CONF_TARGET"
cp "$TMUX_CONF_SRC" "$TMUX_CONF_TARGET"
echo "✓ tmux configuration installed"

# Catppuccin theme setup
echo "🖌️ Setting up Catppuccin theme..."
TMUX_CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin/tmux"
if [ ! -d "$TMUX_CATPPUCCIN_DIR" ]; then
    echo "Cloning Catppuccin theme..."
    mkdir -p "$HOME/.config/tmux/plugins/catppuccin"
    git clone -b v2.1.2 https://github.com/catppuccin/tmux.git "$TMUX_CATPPUCCIN_DIR"
else
    echo "✓ Catppuccin theme already exists"
fi

# Modify theme options
echo "⚙️ Customizing theme options..."
CONFIG_FILE="$TMUX_CATPPUCCIN_DIR/catppuccin_options_tmux.conf"
if [ -f "$CONFIG_FILE" ]; then
    sed -i.bak \
        -e 's/^set -ogq @catppuccin_window_text " #T"$/set -ogq @catppuccin_window_text " #W"/' \
        -e 's/^set -ogq @catppuccin_window_current_text " #T"$/set -ogq @catppuccin_window_current_text " #W"/' \
        "$CONFIG_FILE"
    echo "✓ Theme options customized"
else
    echo "⚠️ Catppuccin config file not found - customization skipped"
fi

echo "🎉 Installation complete! Suggested next steps:"
echo "1. Restart your terminal"
echo "2. Run: tmux source ~/.tmux.conf"
echo "3. Launch nvim and let it install plugins"
