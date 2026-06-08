return {
	{
		"akinsho/bufferline.nvim",
		opts = {
			options = {
				separator_style = "thin",
			},
		},
		config = function(_, opts)
			require("bufferline").setup(opts)


			vim.api.nvim_set_hl(0, "BufferLineBufferSelected", {
				fg = "#ffffff",
				bg = "#0077b6",
				bold = true,
			})

			vim.api.nvim_set_hl(0, "BufferLineTabSelected", {
				fg = "#ffffff",
				bg = "#0077b6",
				bold = true,
			})
		end,
	},
}
