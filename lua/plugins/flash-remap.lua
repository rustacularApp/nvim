local snapback_counter = 0

local function flash_edit_and_return(method)
  snapback_counter = snapback_counter + 1
  local current_win = vim.api.nvim_get_current_win()
  local original_pos = vim.api.nvim_win_get_cursor(current_win)

  -- Trigger the requested Flash action
  require("flash")[method]()

  -- If the cursor didn't move, abort early
  local new_pos = vim.api.nvim_win_get_cursor(current_win)
  if original_pos[1] == new_pos[1] and original_pos[2] == new_pos[2] then
    return
  end

  local group_id = vim.api.nvim_create_augroup("FlashSnapback_" .. snapback_counter, { clear = true })
  
  local triggered = false
  local function safe_snapback()
    if not triggered then
      triggered = true
      if vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_win_set_cursor(current_win, original_pos)
        vim.cmd("normal! zv") -- Open folds if necessary
      end
      pcall(vim.api.nvim_del_augroup_by_id, group_id) -- Self-destruct all hooks
    end
  end

  -- SCENARIO 1: You choose to edit (Insert mode)
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group_id,
    once = true,
    callback = function()
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = group_id,
        once = true,
        callback = safe_snapback,
      })
    end,
  })

  -- SCENARIO 2: You execute a quick action (Yank or Delete) without entering Insert mode
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = group_id,
    callback = function()
      local operator = vim.v.event.operator
      -- 'y' = yank, 'd' = delete/cut. 
      -- We ignore 'c' (change) here so it falls through to the InsertEnter listener above.
      if operator == "y" or operator == "d" then
        safe_snapback()
      end
    end,
  })

  -- Safety Valve: If nothing happens in 15 seconds, clear the hooks
  vim.defer_fn(function()
    pcall(vim.api.nvim_del_augroup_by_id, group_id)
  end, 15000)
end

return {
  {
    "folke/flash.nvim",
    keys = {
      -- Clear conflicting default keys
      { "s", false, mode = { "n", "x", "o" } },
      { "S", false, mode = { "n", "x", "o" } },
      { "r", false, mode = { "o" } },
      { "R", false, mode = { "o", "x" } },
      { "<c-s>", false, mode = { "c" } },
      { "<c-space>", false, mode = { "n", "o", "x" } },

      -- Regular Jumps (Permanent stay)
      { "<leader>fj", function() require("flash").jump() end, desc = "Flash Jump" },
      { "<leader>fJ", function() require("flash").treesitter() end, desc = "Flash Treesitter" },

      -- Normal Mode "Jump, Act, & Snap Back" Workflows
      { "<leader>fk", function() flash_edit_and_return("jump") end, mode = "n", desc = "Flash Action & Return" },
      { "<leader>fK", function() flash_edit_and_return("treesitter_search") end, mode = "n", desc = "Flash TS Action & Return" },
    },
  },
}
