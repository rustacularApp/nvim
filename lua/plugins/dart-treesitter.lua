return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.indent = opts.indent or {}
			opts.indent.disable = opts.indent.disable or {}
			table.insert(opts.indent.disable, "dart")
		end,
	},
}
