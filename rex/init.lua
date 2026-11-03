-- mirroring tmux/.tmux.conf; reloading with ctrl+a r or `rex config reload`

local P = "ctrl+a"

local function pre(key, action, args)
  rex.bind(P .. ">" .. key, action, args)
end

-- passing a literal ctrl+a through (start of line in zsh, increment in nvim)
pre("ctrl+a", "pane.send_key", { key = "ctrl+a" })

pre("c", "client.tab.new")
pre("n", "client.tab.next")
pre("p", "client.tab.previous")
pre(",", "client.tab.rename")
pre("shift+7", "client.tab.close") -- &
for i = 1, 9 do
  pre(tostring(i), "client.tab.goto", { index = i })
end
-- matching chromium's tab switching; up/down keep rex's default pane focus
rex.bind("alt+cmd+left", "client.tab.previous")
rex.bind("alt+cmd+right", "client.tab.next")

pre("shift+5", "pane.split", { direction = "right" }) -- %
pre("shift+'", "pane.split", { direction = "down" }) -- "
pre("o", "pane.focus_next")
pre("z", "pane.zoom")
pre("x", "pane.close")
pre("shift+1", "pane.move_to_new_tab") -- !
pre("shift+e", "pane.balance") -- E

-- also binding ctrl+key, since pressing the prefix then a key quickly often keeps ctrl held
local vim_dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, d in pairs(vim_dirs) do
  pre(key, "pane.focus", { direction = d })
  pre("ctrl+" .. key, "pane.focus", { direction = d })
end
for _, d in ipairs({ "left", "right", "up", "down" }) do
  pre(d, "pane.focus", { direction = d })
  pre("ctrl+" .. d, "pane.focus", { direction = d })
  pre("alt+" .. d, "pane.resize", { direction = d, amount = 5 })
end

-- standing in for tmux's `bind -r` repeat, since rex has no repeat timer
rex.mode("resize", { exclusive = true })
pre("shift+r", "client.mode.enter", { name = "resize" })
for key, d in pairs(vim_dirs) do
  rex.bind("resize/" .. key, "pane.resize", { direction = d })
  rex.bind("resize/shift+" .. key, "pane.resize", { direction = d, amount = 10 })
end
for _, d in ipairs({ "left", "right", "up", "down" }) do
  rex.bind("resize/" .. d, "pane.resize", { direction = d })
  rex.bind("resize/shift+" .. d, "pane.resize", { direction = d, amount = 10 })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")

-- falling back to the session picker for w, since rex has no tab picker
pre("s", "session.switch")
pre("w", "session.switch")
pre("shift+4", "session.rename") -- $
pre("shift+9", "session.previous") -- (
pre("shift+0", "session.next") -- )

pre("shift+;", "client.palette.toggle") -- :
pre("shift+/", "client.palette.toggle") -- ?
pre("r", "client.config.reload")
pre("/", "client.find.open")
pre("shift+s", "client.sidebar.activity.toggle")

local SHELL = "com.superlogical.terminal.shell"

local function focused_cwd(ctx)
  local r = rex.block.call("com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
  if not r or not r.pwd then return nil end
  -- stripping the file://hostname prefix and decoding %20-style escapes
  local path = r.pwd:gsub("^file://[^/]*", "")
  return (path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function folder_name(cwd)
  return cwd and cwd:match("([^/]+)/?$")
end

-- typing the command into an interactive zsh so the claude/codex wrappers
-- (permission flags) apply, and leaving a prompt behind when it exits
local function shell_running(cmd, cwd)
  return rex.layout.block{
    flavor = SHELL,
    options = { cwd = cwd, initial_input = cmd .. "\n" },
  }
end

local AGENT_RATIO = 0.45

rex.action{
  name = "agent_tab",
  title = "Agent in New Tab",
  description = "Opens an agent (claude by default) in a new tab of this session, in this pane's directory.",
  category = "Agents",
  args = { agent = "string?" },
  run = function(ctx, args)
    local agent = args.agent or "claude"
    local cwd = focused_cwd(ctx)
    local folder = folder_name(cwd)
    local _, err = rex.session.new_window{
      window_label = folder and (agent .. " · " .. folder) or agent,
      layout = shell_running(agent, cwd),
    }
    if err then error(err, 0) end
  end,
}

rex.action{
  name = "agent_split",
  title = "Agent Split Here (Left)",
  description = "Opens an agent (claude by default) in a split to the left of this pane, in its directory.",
  category = "Agents",
  args = { agent = "string?" },
  run = function(ctx, args)
    local _, err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "before",
      ratio = AGENT_RATIO,
      focus = true,
      layout = shell_running(args.agent or "claude", focused_cwd(ctx)),
    }
    if err then error(err, 0) end
  end,
}

rex.action{
  name = "agent_workspace",
  title = "New Agent + nvim Tab",
  description = "New tab in this pane's directory: agent (claude by default) on the left, nvim on the right.",
  category = "Agents",
  args = { agent = "string?" },
  run = function(ctx, args)
    local cwd = focused_cwd(ctx)
    local _, err = rex.session.new_window{
      window_label = folder_name(cwd) or "workspace",
      layout = rex.layout.horizontal(AGENT_RATIO,
        shell_running(args.agent or "claude", cwd),
        shell_running("nvim", cwd)),
    }
    if err then error(err, 0) end
  end,
}

rex.action{
  name = "lazygit_popup",
  title = "Lazygit (Floating)",
  description = "Lazygit in a floating pane over this tab; closes when you quit it.",
  category = "Git",
  run = function(ctx, args)
    local _, err = rex.session.new_layer{
      bounds = { 0.05, 0.05, 0.9, 0.9 },
      focus = true,
      layout = rex.layout.block{
        flavor = SHELL,
        options = { cwd = focused_cwd(ctx), command = { "lazygit" } },
      },
    }
    if err then error(err, 0) end
  end,
}

-- snapshotting the pane's scrollback into a read-only nvim, since rex has no
-- copy mode; full-screen programs (nvim, lazygit) keep no scrollback, so for
-- those only the visible screen comes through
local COPY_MODE_SCRIPT = [[
f=$(mktemp -t rex-scrollback)
trap 'rm -f "$f"' EXIT
rex capture -s "$1" -b "$2" --trim --unwrap > "$f" || { echo "capture failed"; sleep 2; exit 1; }
# renaming the buffer so lualine shows "copy-mode" instead of the temp file path
nvim -R -n "$f" -c 'file copy-mode' \
  -c 'setlocal nomodifiable nonumber norelativenumber nolist nospell buftype=nofile' \
  -c 'set clipboard=unnamedplus title titlestring=copy\ mode' \
  -c 'nnoremap <buffer> q <cmd>qa!<cr>' \
  -c 'normal! G$'
]]

rex.action{
  name = "copy_mode",
  title = "Copy Mode (Scrollback in nvim)",
  description = "Opens this pane's screen and scrollback in a floating read-only nvim. y copies to the clipboard, q closes.",
  category = "Pane",
  keywords = "copy scrollback yank select tmux vi",
  run = function(ctx, args)
    local _, err = rex.session.new_layer{
      bounds = { 0, 0, 1, 1 },
      focus = true,
      layout = rex.layout.block{
        flavor = SHELL,
        label = "copy mode",
        options = {
          -- starting in the copied pane's folder, so tabs opened from copy mode land there too
          cwd = focused_cwd(ctx),
          command = { "sh", "-c", COPY_MODE_SCRIPT, "copy_mode", ctx.session_id, ctx.block_id },
        },
      },
    }
    if err then error(err, 0) end
  end,
}

pre("[", "copy_mode")
pre("g", "lazygit_popup")

-- opening the agent in a new tab on its letter, or splitting it in on the
-- left on shift+letter
local AGENTS = { c = "claude", x = "codex" }
for key, agent in pairs(AGENTS) do
  pre("a>" .. key, "agent_tab", { agent = agent })
  pre("a>shift+" .. key, "agent_split", { agent = agent })
end
pre("a>w", "agent_workspace")
