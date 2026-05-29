# Changelog

All notable changes to this dotfiles repo are recorded here.

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
