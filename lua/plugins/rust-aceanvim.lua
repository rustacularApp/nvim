return {
	{
		"mrcjkb/rustaceanvim",
		ft = { "rust" },
		dependencies = { "saghen/blink.cmp" },
		opts = function(_, opts)
			opts.server = opts.server or {}

			-- Injects blink capabilities
			opts.server.capabilities = require("blink.cmp").get_lsp_capabilities(opts.server.capabilities)

			opts.server.on_attach = function(client, bufnr)
				client.server_capabilities.semanticTokensProvider = nil
			end

			opts.server.default_settings = {
				["rust-analyzer"] = {
					-- 1. Restrict symbol search back to workspace only
					workspace = {
						symbol = {
							search = {
								scope = "workspace",
								kind = "only_types",
								limit = 128,
							},
						},
					},
					-- 2. Turn OFF cache priming (stops background 100% CPU lockups)
					cachePriming = { enable = false },
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
						-- 3. CRITICAL: Prevents rust-analyzer from checking every external
						-- trait in sea_query/tokio when typing a period (.)
						autoimport = { enable = false },
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
						allFeatures = false,
						targetDir = false,
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
			}

			return opts
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
