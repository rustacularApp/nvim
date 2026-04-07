return {
	-- {
	-- 	"nvim-treesitter/nvim-treesitter",
	-- 	opts = function(_, opts)
	-- 		opts.indent = opts.indent or {}
	-- 		opts.auto_install = true
	-- 		opts.indent.disable = opts.indent.disable or {}
	-- 		table.insert(opts.indent.disable, "dart")
	-- 	end,
	-- },
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
		opts = {
			ensure_installed = {
				"lua",
				"dart",
				"rust",
				"typescript",
				"tsx",
				"javascript",
				"jsx"
			},
			auto_install = true,
			highlight = {
				enable = true
			},
			indent = {
				enable = true,
				disable = {
					"dart"
				}
			}
		}
	}
}
