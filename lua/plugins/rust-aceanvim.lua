return {
	{
		"mrcjkb/rustaceanvim",
		ft = { "rust" },
		init = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(client, bufnr)
						client.server_capabilities.semanticTokensProvider = nil
					end,
					default_settings = {
						["rust-analyzer"] = {
							workspace = {
								symbol = {
									search = {
										kind = "all_symbols",
										scope = "workspace",
										limit = 256,
									},
								},
							},
							cachePriming = { enable = true },
							procMacro = {
								enable = true,
								ignored = {
									["napi-derive"] = { "napi" },
									["async-trait"] = { "async_trait" },
								},
							},
							inlayHints = {
								enable = false,
								chainingHints = { enable = false },
								typeHints = { enable = false },
								parameterHints = { enable = false },
								renderColons = false,
							},
							completion = {
								callable = { snippets = "add_parentheses" },
								fullFunctionSignatures = { enable = false },
								autoimport = { enable = true },
								postfix = { enable = false },
								termSearch = { enable = false },
							},
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = {
									enable = true,
									rebuildOnSave = false,
								},
							},
							checkOnSave = {
								command = "check",
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
