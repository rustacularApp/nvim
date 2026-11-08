return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = true,
        float = true,
        max_width = 120,
        max_height = 40,
      },
    },
  },
  init = function()
    -- Automatically refresh diagrams when you save the markdown file (:w)
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.md", "*.markdown" },
      group = vim.api.nvim_create_augroup("snacks_diagram_refresh", { clear = true }),
      callback = function(ev)
        -- Reloads buffer silently so Snacks re-renders the diagram
        vim.cmd("edit")
      end,
    })
  end,
}
