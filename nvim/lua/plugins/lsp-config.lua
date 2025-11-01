return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
      "williamboman/mason.nvim",
    },
    lazy = false,
    config = function()
      -- =========================== MANUALLY ENABLED VIRTUAL TEXT DIAGNOSTICS ===========================
      -- I've had to do this manually because neovim's v0.11.0+ does not have this turned on by default.
      -- also, I've had to remove mason-lspconfig because it was causing duplicate diagnostics (and that
      -- it would be redundant as well due to this new neovim update)
      vim.diagnostic.config({
        virtual_text = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
          },
        },
        underline = true,
        update_in_insert = false,
      })
      -- =========================== MANUALLY ENABLED VIRTUAL TEXT DIAGNOSTICS END ===========================

      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lsp = vim.lsp

      -- Migrated to new lsp.config() and lsp.enable() API (Neovim 0.11+) since
      -- the old require('lspconfig') API is deprecated

      -- Helper function to safely enable LSP servers with error handling
      local function setup_lsp(name, config)
        config = config or {}
        config.capabilities = config.capabilities or capabilities

        local ok, err = pcall(function()
          lsp.config(name, config)
          lsp.enable(name)
        end)

        if not ok then
          vim.notify(string.format("Failed to setup LSP server '%s': %s", name, err), vim.log.levels.WARN)
        end
      end

      -- Lua
      setup_lsp("lua_ls")
      -- Astro
      setup_lsp("astro", {
        filetypes = { "astro", "mdx" },
        on_attach = function(client, _)
          client.server_capabilities.definitionProvider = true
        end,
      })

      -- TypeScript/JavaScript
      setup_lsp("ts_ls", {
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "mdx" },
        init_options = {
          preferences = {
            importModuleSpecifierPreference = "relative",
            includeInlayParameterNameHints = "all",
          },
        },
      })

      -- Python (Pyright for LSP features + Ruff for linting)
      setup_lsp("pyright")
      setup_lsp("ruff")

      -- Markdown
      setup_lsp("marksman")

      -- Clangd (C/C++)
      setup_lsp("clangd")

      -- VimLS (VimScript)
      setup_lsp("vimls")

      -- Zig
      setup_lsp("zls")

      -- LSP Keymaps
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {
        desc = "Go to declaration",
      })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {
        desc = "Show hover documentation",
      })
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
        desc = "Go to definition",
      })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, {
        desc = "Show references",
      })
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {
        desc = "Go to implementation",
      })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {
        desc = "Show code actions",
      })
    end,
  },
}
