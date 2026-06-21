return {
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000,
		config = function()
			require("onedarkpro").setup({
				options = {
					transparency = false
				}
			})
			vim.cmd("colorscheme vaporwave")
		end,
	},
}
