return {
	{
		"mrcjkb/rustaceanvim",
		ft = { "rust" },
		init = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(client, bufnr)
						-- Keeps syntax highlighting snappy in huge files
						client.server_capabilities.semanticTokensProvider = nil
					end,
					extraEnv = {
						-- Isolates RA builds so it never locks your terminal cargo builds
						CARGO_TARGET_DIR = "target/rust-analyzer",
						-- Caps RA background CPU usage to 2 cores
						CARGO_BUILD_JOBS = "2",
					},
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
							-- Keep cache priming ON so completions are instant
							cachePriming = { enable = true },
							procMacro = {
								enable = true,
								ignored = {
									["napi-derive"] = { "napi" },
									["async-trait"] = { "async_trait" },
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
								-- REQUIRED for axum / sea_orm / struct suggestions
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
								allFeatures = true,
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
