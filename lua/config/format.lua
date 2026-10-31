local M = {}

local patterns = {
	"*.lua",
	"*.py",
	"*.go",
	"*.js",
	"*.jsx",
	"*.ts",
	"*.tsx",
	"*.json",
	"*.css",
	"*.scss",
	"*.html",
	"*.sh",
	"*.bash",
	"*.zsh",
	"*.c",
	"*.cpp",
	"*.h",
	"*.hpp",
}

local function enabled(buf)
	if vim.b[buf].autoformat_enabled ~= nil then
		return vim.b[buf].autoformat_enabled
	end
	return vim.g.autoformat_enabled ~= false
end

local function efm_attached(buf)
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		if client.name == "efm" then
			return true
		end
	end
	return false
end

function M.format(buf, notify_when_missing)
	buf = buf or vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or vim.api.nvim_buf_get_name(buf) == "" then
		return false
	end
	if not efm_attached(buf) then
		if notify_when_missing then
			vim.notify("No EFM formatter attached to this buffer", vim.log.levels.WARN)
		end
		return false
	end

	local ok, err = pcall(vim.lsp.buf.format, {
		bufnr = buf,
		timeout_ms = 2000,
		filter = function(client)
			return client.name == "efm"
		end,
	})
	if not ok and notify_when_missing then
		vim.notify("Formatting failed: " .. tostring(err), vim.log.levels.ERROR)
	end
	return ok
end

function M.status(buf)
	return enabled(buf or vim.api.nvim_get_current_buf()) and "" or " FMT:off "
end

local function notify_state(scope, value)
	vim.notify(("Autoformat %s for %s"):format(value and "enabled" or "disabled", scope))
	vim.cmd("redrawstatus")
end

local function setup_efm()
	local luacheck = require("efmls-configs.linters.luacheck")
	local stylua = require("efmls-configs.formatters.stylua")
	local black = require("efmls-configs.formatters.black")
	local prettier_d = require("efmls-configs.formatters.prettier_d")
	local eslint_d = require("efmls-configs.linters.eslint_d")
	local fixjson = require("efmls-configs.formatters.fixjson")
	local shellcheck = require("efmls-configs.linters.shellcheck")
	local shfmt = require("efmls-configs.formatters.shfmt")
	local cpplint = require("efmls-configs.linters.cpplint")
	local clangfmt = require("efmls-configs.formatters.clang_format")
	local go_revive = require("efmls-configs.linters.go_revive")
	local gofumpt = require("efmls-configs.formatters.gofumpt")
	vim.lsp.config("efm", {
		filetypes = {
			"c",
			"cpp",
			"css",
			"go",
			"html",
			"javascript",
			"javascriptreact",
			"json",
			"jsonc",
			"lua",
			"markdown",
			"python",
			"sh",
			"bash",
			"zsh",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
		},
		init_options = { documentFormatting = true },
		settings = {
			languages = {
				c = { clangfmt, cpplint },
				go = { gofumpt, go_revive },
				cpp = { clangfmt, cpplint },
				css = { prettier_d },
				html = { prettier_d },
				javascript = { eslint_d, prettier_d },
				javascriptreact = { eslint_d, prettier_d },
				json = { eslint_d, fixjson },
				jsonc = { eslint_d, fixjson },
				lua = { luacheck, stylua },
				markdown = { prettier_d },
				python = { black },
				sh = { shellcheck, shfmt },
				bash = { shellcheck, shfmt },
				zsh = { shellcheck, shfmt },
				typescript = { eslint_d, prettier_d },
				typescriptreact = { eslint_d, prettier_d },
				vue = { eslint_d, prettier_d },
				svelte = { eslint_d, prettier_d },
			},
		},
	})
end

function M.setup()
	setup_efm()
	if vim.g.autoformat_enabled == nil then
		vim.g.autoformat_enabled = true
	end

	local group = vim.api.nvim_create_augroup("UserConfigFormat", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		pattern = patterns,
		callback = function(args)
			if enabled(args.buf) then
				M.format(args.buf, false)
			end
		end,
	})

	vim.api.nvim_create_user_command("Format", function()
		M.format(0, true)
	end, { force = true, desc = "Format the current buffer with EFM" })

	vim.api.nvim_create_user_command("FormatToggle", function(opts)
		if opts.bang then
			vim.g.autoformat_enabled = not (vim.g.autoformat_enabled ~= false)
			notify_state("all buffers", vim.g.autoformat_enabled)
		else
			local buf = vim.api.nvim_get_current_buf()
			vim.b[buf].autoformat_enabled = not enabled(buf)
			notify_state("this buffer", vim.b[buf].autoformat_enabled)
		end
	end, { bang = true, force = true, desc = "Toggle buffer autoformat; use ! for global" })

	_G.format_status = M.status
end

return M
