return {
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "saghen/blink.cmp", -- Ensure blink is a dependency
    },
    config = function()
      -- Fetch the capabilities from blink.cmp
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      require("flutter-tools").setup({
        dev_log = {
          enabled = true,
          open_cmd = "tabedit"
        },
        lsp = {
          -- Inject the capabilities here
          capabilities = capabilities,
          color_capabilities = true,
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            -- Recommended: Enable closing labels (those grey comments at the end of widgets)
            closingLabels = true,
          },
        },
      })
    end,
  },
}
