return {
	{
		"mrcjkb/rustaceanvim",
		ft = { "rust" },
		dependencies = { "saghen/blink.cmp" },
		init = function()
			vim.g.rustaceanvim = {
				server = {
					-- 1. Injects blink capabilities so lazy-resolution works
					capabilities = require("blink.cmp").get_lsp_capabilities(),
					on_attach = function(client, bufnr)
						client.server_capabilities.semanticTokensProvider = nil
					end,
					default_settings = {
						["rust-analyzer"] = {
							workspace = {
								symbol = {
									search = {
										kind = "all_symbols",
										scope = "workspace_and_dependencies",
										excludeImports = false,
										limit = 256,
									},
								},
							},
							cachePriming = { enable = true },
							procMacro = {
								enable = true,
								ignored = {
									["napi-derive"] = { "napi" },
								},
							},
							inlayHints = {
								chainingHints = { enable = false },
								typeHints = { enable = true },
								parameterHints = { enable = true },
								renderColons = true,
							},
							completion = {
								callable = { snippets = "add_parentheses" },
								fullFunctionSignatures = { enable = false },
								autoimport = { enable = true },
								postfix = { enable = false },
							},
							imports = {
								granularity = { group = "module" },
								prefix = "self",
							},
							diagnostics = {
								enable = true,
								disabled = { "unresolved-proc-macro" },
							},
							cargo = {
								allFeatures = false, -- DISABLED: massive speedup on sea_query/deps
								targetDir = true,     -- properly isolates cache to target/rust-analyzer
								loadOutDirsFromCheck = true,
								buildScripts = { enable = true },
							},
							checkOnSave = {
								command = "clippy",
								extraArgs = { "--no-deps" },
							},
							files = {
								excludeDirs = {
									".dart_tool",
									".flutter-plugins",
									".flutter-plugins-dependencies",
									"build",
									"target",
									"node_modules",
									".git",
								},
							},
						},
					},
				},
			}
		end,
	},
	{
		"statiolake/rust-import.nvim",
		ft = "rust",
		dependencies = { "mrcjkb/rustaceanvim" },
		config = function()
			require("rust-import").setup()
		end,
		keys = {
			{
				"<leader>cb",
				"<cmd>RustOrganizeImports<cr>",
				desc = "Source Action (Clean & Organize Imports)",
			},
		},
	},
}
