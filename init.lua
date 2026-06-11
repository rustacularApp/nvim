
local is_vps = vim.env.IS_VPS == "true"

vim.g.is_vps_env = is_vps

require("config.lazy")

require("vim._core.ui2").enable({
	enable = false
})

require('plugins.coercion')
