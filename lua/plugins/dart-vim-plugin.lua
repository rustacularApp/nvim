return {
	{
		"dart-lang/dart-vim-plugin",
		ft = { "dart" },
		init = function ()
			vim.g.dart_format_on_save = 0
		end
	},
}
