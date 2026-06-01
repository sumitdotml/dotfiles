# Changelog

All notable changes to this dotfiles repo are recorded here.

## 2026-06-01

### Added

- Added global Codex writing preferences in `codex/AGENTS.md` for clearer, more reader-friendly docs and research notes.

## [0.2.0] - 2026-05-31

### Changed

- Reworked `install.sh` into an interactive installer that asks before setting up dependencies, config symlinks, and the tmux Catppuccin theme customization.
- Made config symlinking explicit for Neovim, tmux, Ghostty, Kitty, and Vim while leaving `zsh` and `cc` files unmanaged by the installer.
- Raised the Neovim requirement for this branch to `>= 0.12.0` and added guidance to use the older branch for `<= 0.11` setups.
- Switched Neovim installation to the official GitHub release archive instead of requiring Homebrew.
- Kept `tree-sitter` installation on the official GitHub release binary path.
- Unified `tree-sitter-cli` install into a single curl-based path for macOS and Linux (`install_tree_sitter_cli`), with `uname -m` arch detection for `x64`/`arm64` and an explicit failure if `tree-sitter` is not on `PATH` after the install completes.
- Made tmux and git dependency setup platform-aware:
  - macOS uses Homebrew or MacPorts for tmux when available, with Homebrew installation offered only when needed.
  - Linux uses the detected system package manager (`apt`, `dnf`, `yum`, or `pacman`) for tmux and git.
  - macOS git setup uses Apple's Xcode Command Line Tools prompt when git is missing.
- Preserved the tmux Catppuccin `#T` to `#W` window-name customization and made it idempotent when already applied.

### Fixed

- Made repeated config setup safer by leaving already-correct symlinks untouched instead of backing them up and recreating them every run.
- Replaced the previous `sort -V` Neovim version comparison with a shell-native comparison that works on default macOS.

## [0.1.0] - 2026-05-29

### Changed

- Updated `nvim-treesitter` usage for the `main` branch API:
  - Renamed the eager parser list to `bootstrap_parsers`.
  - Removed startup-time installation of the entire parser list.
  - Added lazy per-file parser installation for supported filetypes that are opened before their parser is installed.
  - Removed stale `jsonc` parser installation; `jsonc` filetypes are handled by the `json` parser.
- Expanded the Treesitter bootstrap parser list with common web, infra, and application languages including `ini`, `jinja`, `json5`, `jsonnet`, `just`, `kotlin`, `latex`, `mermaid`, `nix`, `php`, `prisma`, `ruby`, `scss`, `svelte`, `terraform`, and `vue`.
- Updated Telescope from the old `0.1.8` tag to the semver range `^0.2.0`, currently resolving to `v0.2.2`.
- Removed the temporary Telescope preview workaround after upgrading to a Telescope version that uses Neovim core Treesitter APIs instead of the removed `nvim-treesitter.parsers.ft_to_lang` API.

### Fixed

- Documented the parser/tooling expectations introduced by lazy Treesitter parser installation and Telescope `live_grep`.
- Resolved the Telescope preview compatibility issue caused by the removed `nvim-treesitter.parsers.ft_to_lang` API.

### Requirements

- `tree-sitter` must be available on `PATH` for Treesitter parser builds.
- `rg` must be available on `PATH` for Telescope `live_grep` (`<leader>fg`).

### Migration Notes

- After switching to the `nvim-treesitter` `main` branch API, existing parser caches may need to be rebuilt if parser and query revisions are out of sync.
- Older Linux distributions may need a locally compatible `tree-sitter` binary if upstream prebuilt binaries require a newer system C library.
- Clearing stale Neovim compiled Lua cache can help after plugin API upgrades if old modules continue to load.
- Homebrew has split the `tree-sitter` formula: `brew install tree-sitter` now installs only the `libtree-sitter` C library, and the CLI binary required by `nvim-treesitter` builds lives in `brew install tree-sitter-cli`. The installer's curl-based path sidesteps the split and works regardless of which (if either) brew formula is present.
