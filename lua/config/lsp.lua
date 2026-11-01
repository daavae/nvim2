local M = {}

function M.setup()
	if vim.fn.exists(":LspRestart") == 0 then
		vim.api.nvim_create_user_command("LspRestart", function()
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
				client:stop(true)
			end
			vim.defer_fn(function()
				pcall(vim.cmd, "edit")
			end, 100)
		end, { nargs = 0 })
	end

	vim.lsp.config("lua_ls", {
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				telemetry = { enable = false },
			},
		},
	})
	-- Keep native progress events without rendering Pyright's frequent analysis popups.
	local progress_handler = vim.lsp.handlers["$/progress before mini.notify"] or vim.lsp.handlers["$/progress"]
	vim.lsp.config("pyright", {
		handlers = { ["$/progress"] = progress_handler },
	})
	for _, client in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
		client.handlers["$/progress"] = progress_handler
	end
	vim.lsp.config("bashls", { filetypes = { "sh", "bash", "zsh" } })
	-- TypeScript 7+ is the native port: it has no tsserver.js (so ts_ls can't use it),
	-- but its tsc ships a built-in LSP. Route each project to the matching server.
	local function native_ts(root)
		if vim.fn.executable(root .. "/node_modules/.bin/tsgo") == 1 then
			return root .. "/node_modules/.bin/tsgo"
		end
		local ok, pkg = pcall(function()
			return vim.json.decode(table.concat(vim.fn.readfile(root .. "/node_modules/typescript/package.json"), "\n"))
		end)
		local major = ok and pkg and tonumber(tostring(pkg.version):match("^(%d+)"))
		if major and major >= 7 then
			return root .. "/node_modules/.bin/tsc"
		end
	end
	local function filter_root(name, want_native)
		local default_root = vim.lsp.config[name].root_dir
		return function(bufnr, on_dir)
			default_root(bufnr, function(root)
				if (native_ts(root) ~= nil) == want_native then
					on_dir(root)
				end
			end)
		end
	end
	vim.lsp.config("ts_ls", { root_dir = filter_root("ts_ls", false) })
	vim.lsp.config("tsgo", {
		root_dir = filter_root("tsgo", true),
		cmd = function(dispatchers, config)
			return vim.lsp.rpc.start({ native_ts(config.root_dir), "--lsp", "--stdio" }, dispatchers)
		end,
	})
	vim.lsp.config("gopls", {})
	vim.lsp.config("clangd", {})
	vim.lsp.enable({ "lua_ls", "pyright", "bashls", "ts_ls", "tsgo", "gopls", "clangd", "efm" })
end

return M
