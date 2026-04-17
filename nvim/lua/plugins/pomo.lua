return {
  {
    "epwalsh/pomo.nvim",
    version = "*",
    lazy = true,
    cmd = { "TimerStart", "TimerRepeat", "TimerSession" },
    keys = {
      {
        "<leader>pt",
        function()
          require("telescope").load_extension("pomodori")
          require("telescope").extensions.pomodori.timers(
            require("telescope.themes").get_dropdown({ previewer = false })
          )
        end,
        desc = "Manage Pomodori Timers",
      },
    },
    dependencies = {
      "rcarriga/nvim-notify",
    },
    opts = function()
      local uname = vim.loop.os_uname()
      local is_wsl = uname.release:lower():find("microsoft") ~= nil
      local is_macos = uname.sysname == "Darwin"
      local has_system_notifier = is_macos
          or (uname.sysname == "Linux" and not is_wsl)

      local notifiers = {
        {
          name = "Default",
          opts = {
            sticky = false,
            title_icon = "󱎫",
            text_icon = "󰄉",
          },
        },
      }
      if has_system_notifier then
        table.insert(notifiers, { name = "System" })
      end
      if is_macos then
        local sound = "/System/Library/Sounds/Hero.aiff"
        table.insert(notifiers, {
          init = function()
            return {
              tick = function() end,
              start = function() end,
              stop = function() end,
              done = function()
                vim.system({ "afplay", sound }, { detach = true })
              end,
            }
          end,
        })
      end

      return {
        update_interval = 1000,
        notifiers = notifiers,
        timers = {},
        sessions = {
          -- Classic pomodoro: 25m work cycles
          -- Start with :TimerSession pomodoro
          pomodoro = {
            { name = "Work",        duration = "25m" },
            { name = "Short Break", duration = "5m" },
            { name = "Work",        duration = "25m" },
            { name = "Short Break", duration = "5m" },
            { name = "Work",        duration = "25m" },
            { name = "Long Break",  duration = "15m" },
          },
          -- Deep work: 50m work cycles
          -- Start with :TimerSession deep
          deep = {
            { name = "Work",        duration = "50m" },
            { name = "Short Break", duration = "10m" },
            { name = "Work",        duration = "50m" },
            { name = "Short Break", duration = "10m" },
            { name = "Work",        duration = "50m" },
            { name = "Long Break",  duration = "20m" },
          },
        },
      }
    end,
  },
}
