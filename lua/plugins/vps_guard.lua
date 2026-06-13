
-- IF WE ARE LOCAL: Do absolutely nothing.
if not vim.g.is_vps_env then
    return {}
end

return {
	{
		"mrcjkb/rustaceanvim",
		enabled = false
	},
	{
		"nvim-flutter/flutter-tools.nvim",
		enabled = false
	},
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            opts.servers = {} -- Tells lspconfig not to initialize any server binaries
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {}, -- Prevents Mason from trying to auto-download them
        },
    },
    { "yionoom/vtsls.nvim", enabled = false },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {}, -- Wipes out formatting assignments per file type
        },
    },
    {
        "mfussenegger/nvim-lint",
        opts = {
            linters_by_ft = {}, -- Wipes out linting assignments per file type
        },
    },
}
