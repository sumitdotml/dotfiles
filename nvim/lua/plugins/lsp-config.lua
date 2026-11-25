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

      -- Python (basedpyright for LSP features + Ruff for linting)
      -- basedpyright replaced pyright, which sends no inlay hints. It still shows no hint
      -- for positional-only parameters such as range(stop), and has no setting for that.
      setup_lsp("basedpyright", {
        settings = {
          basedpyright = {
            analysis = {
              -- Same as Vim's coc-settings.json. basedpyright's default, "recommended", is much stricter
              typeCheckingMode = "basic",
              inlayHints = {
                callArgumentNames = true,
                variableTypes = false,
                functionReturnTypes = false,
              },
            },
          },
        },
      })
      setup_lsp("ruff")

      -- Markdown
      setup_lsp("marksman")

      -- Clangd (C/C++) - prefer Homebrew LLVM for CUDA support, fall back to system
      local clangd_cmd = "clangd"
      for _, candidate in ipairs({
        "/opt/homebrew/opt/llvm/bin/clangd",
        "/usr/local/opt/llvm/bin/clangd",
      }) do
        if vim.fn.executable(candidate) == 1 then
          clangd_cmd = candidate
          break
        end
      end
      setup_lsp("clangd", {
        cmd = { clangd_cmd },
      })

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

      vim.lsp.inlay_hint.enable(true)
      vim.keymap.set("n", "<leader>th", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end, {
        desc = "Toggle inlay hints",
      })

      -- Highlight other uses of the symbol under the cursor once the cursor rests for
      -- 'updatetime' ms (CursorHold), the same way coc does it in Vim
      vim.g.reference_highlight = true
      local reference_group = vim.api.nvim_create_augroup("lsp-reference-highlight", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = reference_group,
        callback = function(args)
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          -- Some servers, such as ruff, can't find references. A buffer with only those
          -- would show a "method not supported" error on every CursorHold.
          if not client:supports_method("textDocument/documentHighlight", args.buf) then
            return
          end
          -- Clearing first, so a second server or :LspRestart doesn't add duplicate autocmds
          vim.api.nvim_clear_autocmds({ group = reference_group, buffer = args.buf })
          vim.api.nvim_create_autocmd("CursorHold", {
            group = reference_group,
            buffer = args.buf,
            callback = function()
              if vim.g.reference_highlight then
                vim.lsp.buf.document_highlight()
              end
            end,
          })
          vim.api.nvim_create_autocmd("CursorMoved", {
            group = reference_group,
            buffer = args.buf,
            callback = function()
              vim.lsp.buf.clear_references()
            end,
          })
        end,
      })
      vim.keymap.set("n", "<leader>tr", function()
        vim.g.reference_highlight = not vim.g.reference_highlight
        vim.lsp.buf.clear_references()
      end, {
        desc = "Toggle highlighting other uses of the symbol under the cursor",
      })
    end,
  },
}
