return {
	{
		"nvim-flutter/flutter-tools.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"saghen/blink.cmp", -- Ensure blink is a dependency
		},
		config = function()
			local capabilities = require('blink.cmp').get_lsp_capabilities()

			require("flutter-tools").setup({
				dev_log = {
					enabled = true,
					open_cmd = "tabedit"
				},
				lsp = {
					capabilities = capabilities,
					color_capabilities = true,
					-- on_attach = function (_, bufnr)
					-- 	vim.api.nvim_create_autocmd("BufWritePre", {
					-- 		buffer = bufnr,
					-- 		callback = function ()
					-- 			if vim.bo[bufnr].filetype == "dart" then
					-- 				vim.lsp.buf.format({ async = false })
					-- 			end
					-- 		end
					-- 	})
					-- end,
					settings = {
						showTodos = true,
						completeFunctionCalls = true,
						closingLabels = true,
						displayInlayHints = false,
						lineLength = 120
					},
				},
			})
		end,
	},
}
