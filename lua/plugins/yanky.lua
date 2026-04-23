return {
	{
		"gbprod/yanky.nvim",
		dependencies = { { "kkharji/sqlite.lua" } },
		opts = {
			storage = "sqlite",
			sync_with_numbered_registers = true,
		},
	},
}
