local M = type(package.loaded["config.lsp_ui"]) == "table" and package.loaded["config.lsp_ui"] or {}

local diagnostic_modes = {
	{ name = "virtual text", config = { virtual_text = { prefix = "●", spacing = 4 }, virtual_lines = false } },
	{ name = "virtual lines", config = { virtual_text = false, virtual_lines = { current_line = true } } },
	{ name = "signs only", config = { virtual_text = false, virtual_lines = false } },
}
M.diagnostic_mode = M.diagnostic_mode or 1
M.open_floating_preview = M.open_floating_preview or vim.lsp.util.open_floating_preview

local function toggle_feature(label, feature)
	return function()
		local filter = { bufnr = 0 }
		local enabled = not feature.is_enabled(filter)
		feature.enable(enabled, filter)
		vim.notify(label .. " " .. (enabled and "enabled" or "disabled"))
	end
end

local function highlights()
	local yellow = "#e0af68"
	vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = yellow })
	vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = yellow, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DiagnosticSignWarn", { fg = yellow })
	vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = yellow })
end

local function signature_help(err, result, ctx, config)
	local bufnr = ctx and ctx.bufnr
	if bufnr and not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	-- Empty responses must close the previous signature popup.
	if bufnr and (result == nil or result.signatures == nil or vim.tbl_isempty(result.signatures)) then
		local winid = vim.b[bufnr].signature_help_winid
		if winid and vim.api.nvim_win_is_valid(winid) then
			pcall(vim.api.nvim_win_close, winid, true)
		end
		vim.b[bufnr].signature_help_winid = nil
		return
	end
	config = vim.tbl_deep_extend("force", {
		border = "rounded",
		focusable = false,
		close_events = { "InsertLeave", "BufHidden", "CursorMoved", "CursorMovedI" },
	}, config or {})
	local handler_result, winid = vim.lsp.handlers.signature_help(err, result, ctx, config)
	if bufnr then
		vim.b[bufnr].signature_help_winid = winid and vim.api.nvim_win_is_valid(winid) and winid or nil
	end
	return handler_result, winid
end

function M.setup()
	vim.diagnostic.config({
		virtual_text = { prefix = "●", spacing = 4 },
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = " ",
				[vim.diagnostic.severity.WARN] = " ",
				[vim.diagnostic.severity.INFO] = "",
				[vim.diagnostic.severity.HINT] = "",
			},
		},
		underline = true,
		update_in_insert = false,
		severity_sort = true,
		float = {
			border = "rounded",
			source = true,
			header = "",
			prefix = "",
			focusable = false,
			style = "minimal",
		},
	})
	vim.diagnostic.config(diagnostic_modes[M.diagnostic_mode].config)
	highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("UserConfigLspUI", { clear = true }),
		callback = highlights,
	})
	vim.lsp.util.open_floating_preview = function(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return M.open_floating_preview(contents, syntax, opts, ...)
	end
	vim.lsp.handlers["textDocument/signatureHelp"] = signature_help

	vim.api.nvim_create_user_command("LspInlayHintsToggle", toggle_feature("Inlay hints", vim.lsp.inlay_hint), {
		force = true,
		desc = "Toggle LSP inlay hints for the current buffer",
	})
	vim.api.nvim_create_user_command(
		"LspSemanticTokensToggle",
		toggle_feature("Semantic tokens", vim.lsp.semantic_tokens),
		{
			force = true,
			desc = "Toggle LSP semantic tokens for the current buffer",
		}
	)
	vim.api.nvim_create_user_command("DiagnosticMode", function()
		M.diagnostic_mode = M.diagnostic_mode % #diagnostic_modes + 1
		local mode = diagnostic_modes[M.diagnostic_mode]
		vim.diagnostic.config(mode.config)
		vim.notify("Diagnostics: " .. mode.name)
	end, { force = true, desc = "Cycle diagnostics through virtual text, virtual lines, and signs only" })
	vim.keymap.set("n", "<leader>ti", "<cmd>LspInlayHintsToggle<CR>", { desc = "Toggle inlay hints" })
	vim.keymap.set("n", "<leader>tS", "<cmd>LspSemanticTokensToggle<CR>", { desc = "Toggle semantic tokens" })
	vim.keymap.set("n", "<leader>dv", "<cmd>DiagnosticMode<CR>", { desc = "Cycle diagnostic display" })
	vim.keymap.set("n", "<leader>td", function()
		vim.diagnostic.enable(not vim.diagnostic.is_enabled())
	end, { desc = "Toggle diagnostics" })
	vim.keymap.set("n", "<leader>ts", function()
		local winid = vim.b.signature_help_winid
		if winid and vim.api.nvim_win_is_valid(winid) then
			pcall(vim.api.nvim_win_close, winid, true)
			vim.b.signature_help_winid = nil
			return
		end
		vim.lsp.buf.signature_help()
	end, { desc = "Signature help" })
	vim.keymap.set("n", "<leader>q", function()
		vim.diagnostic.setloclist({ open = true })
	end, { desc = "Open diagnostic list" })
end

return M
