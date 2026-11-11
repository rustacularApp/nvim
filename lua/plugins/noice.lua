return {
  {
    "folke/noice.nvim",
    opts = {
      views = {
        confirm = {
          border = {
            style = "rounded",
            padding = { 1, 3 }, -- { top/bottom: 1 line, left/right: 3 cols }
          },
          size = {
            min_width = 65, -- ensures it never shrinks below 65 characters wide
            width = "auto",
            height = "auto",
          },
          position = {
            row = "50%",
            col = "50%",
          },
        },
      },
    },
  },
}
