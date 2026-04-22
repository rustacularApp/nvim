return {
	-- Syntax highlighting
	{
		"chomosuke/typst-preview.nvim",
		lazy = false, -- Load on startup for typst files
		version = "1.*",
		build = function() require 'typst-preview'.update() end,
		opts = {},
	},
	-- Ensure Tinymist is managed by Mason/lspconfig
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				tinymist = {
					-- Offset encoding fix for some terminal setups
					offset_encoding = "utf-16", 
				},
			},
		},
	},
}
