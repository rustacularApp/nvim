return {
  -- 1. Image rendering backend
  {
    "3rd/image.nvim",
    build = false, -- Avoid LuaRocks build steps; use system magick CLI instead
    opts = {
      processor = "magick_cli", -- Uses system ImageMagick directly
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },
      max_width = 100,
      max_height = 25,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
    },
  },

  -- 2. Diagram as code viewer
  {
    "3rd/diagram.nvim",
    dependencies = {
      "3rd/image.nvim",
    },
    opts = {
      events = {
        render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
        clear_buffer = { "BufLeave" },
      },
      renderer_options = {
        mermaid = {
          theme = "dark", -- Options: "default" | "dark" | "forest" | "neutral"
          scale = 1.2,
        },
        d2 = {
          theme_id = 200, -- Dark theme for D2
          scale = -1,
        },
        plantuml = {
          charset = "utf-8",
        },
      },
    },
    keys = {
      {
        "K",
        function()
          require("diagram").show_diagram_hover()
        end,
        mode = "n",
        ft = { "markdown", "norg" },
        desc = "Diagram: View Hover/Tab Preview",
      },
    },
  },
}
