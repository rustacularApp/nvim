return {
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        STEP = {
			icon = "🪜",
			color = "info",
			alt = {"step", "Step"}
		},
      },
      search = {
        pattern = [[\b(TODO|FIX|FIXME|BUG|HACK|WARN|WARNING|PERF|NOTE|TEST):]],
      },
    },
    keys = {
      -- 1. Standard search (<leader>st) to exclude STEP globally
      {
        "<leader>st",
        function()
          local has_snacks, snacks = pcall(require, "snacks")
          if has_snacks then
            snacks.picker.todo_comments({
              keywords = { "TODO", "FIX", "FIXME", "HACK", "WARN", "PERF", "NOTE", "TEST" },
            })
          else
            vim.cmd("TodoTelescope keywords=TODO,FIX,FIXME,HACK,WARN,PERF,NOTE,TEST")
          end
        end,
        desc = "Todo (excluding STEP)",
      },

      -- 2. Find only STEP comments in the current file (<leader>fs)
      {
        "<leader>fs",
        function()
          local current_file = vim.api.nvim_buf_get_name(0)
          if current_file == "" then
            vim.notify("No active file in the current buffer", vim.log.levels.WARN)
            return
          end

          local has_snacks, snacks = pcall(require, "snacks")
          if has_snacks then
            -- Searches only "STEP" in the current file using snacks.picker
            snacks.picker.todo_comments({
              keywords = { "STEP" },
              dirs = { current_file },
            })
          else
            local has_telescope, telescope = pcall(require, "telescope")
            if has_telescope then
              -- Searches only "STEP" in the current file using Telescope
              telescope.extensions["todo-comments"].todo({
                keywords = { "STEP" },
                search_dirs = { current_file },
              })
            else
              -- Fallback: uses the built-in location list for the current buffer
              vim.cmd("TodoLocList keywords=STEP")
            end
          end
        end,
        desc = "Find STEP comments in current file",
      },
    },
  },
}
