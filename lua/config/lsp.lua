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
	vim.lsp.config("ts_ls", {})
	vim.lsp.config("gopls", {})
	vim.lsp.config("clangd", {})
	vim.lsp.enable({ "lua_ls", "pyright", "bashls", "ts_ls", "gopls", "clangd", "efm" })
end

return M
