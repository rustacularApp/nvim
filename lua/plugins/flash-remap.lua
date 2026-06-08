return {
  {
    "folke/flash.nvim",
    keys = {
      { "s", false, mode = { "n", "x", "o" } },
      { "S", false, mode = { "n", "x", "o" } },
      { "r", false, mode = { "o" } },
      { "R", false, mode = { "o", "x" } },
      { "<c-s>", false, mode = { "c" } },
      { "<c-space>", false, mode = { "n", "o", "x" } },

      { "<leader>fj", function() require("flash").jump() end, desc = "Flash Jump" },
      { "<leader>fJ", function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "<leader>fr", function() require("flash").remote() end, mode = "o", desc = "Flash Remote" },
      { "<leader>fR", function() require("flash").treesitter_search() end, mode = { "o", "x" }, desc = "Flash TS Search" },
    },
  },
}
