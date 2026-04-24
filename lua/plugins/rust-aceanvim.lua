return {
	{
		"mrcjkb/rustaceanvim",
		ft = { "rust" },
		init = function ()
			vim.g.rustaceanvim = {
				server = {
					extraEnv = { CARGO_TARGET_DIR = "target/rust-analyzer" },
					settings = {
						['rust-analyzer'] = {
							procMacro = {
								enable = true,
								ignored = {
									["async-trait"] = { "async_trait" },
									["napi-derive"] = { "napi" },
								},
							},
							diagnostics = {
								enable = true,
								disabled = { "unresolved-proc-macro" },
							},
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = {
									enable = true,
								},
							},
							checkOnSave = {
								command = "clippy",
								extraArgs = { "--no-deps" },
							},
						},
					},
				},
			}
		end
	}
}
