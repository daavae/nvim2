require("config.environment").setup()
require("config.options").setup()

local local_ok, local_config = pcall(require, "config.local")
local plugins = require("config.plugins").setup(local_ok and local_config.plugins or nil)
if local_ok and type(local_config.setup) == "function" then
	local_config.setup(plugins)
end

require("config.appearance").setup()
require("config.statusline").setup()
require("config.tabline").setup()
require("config.keymaps").setup()
require("config.autocmds").setup()

require("config.treesitter").setup()
require("config.mini").setup()
require("config.indent").setup()
require("config.pickers").setup(plugins)
require("config.git").setup()
require("config.markdown").setup(plugins)
require("config.json").setup()
require("config.oil").setup(plugins)
require("config.todo").setup()
require("config.tasks").setup()
require("config.update_remote").setup()
require("config.sessions").setup()
require("config.terminal").setup(require("config.keymaps").smart_navigate)

require("config.format").setup()
require("config.lsp_ui").setup()
require("config.lsp_attach").setup()
require("config.lsp").setup()
