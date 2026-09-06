local M = {}

local diagnostic_modes = {
	{ name = "virtual text", config = { virtual_text = { prefix = "●", spacing = 4 }, virtual_lines = false } },
	{ name = "virtual lines", config = { virtual_text = false, virtual_lines = { current_line = true } } },
	{ name = "signs only", config = { virtual_text = false, virtual_lines = false } },
}
local diagnostic_mode = 1

local function toggle_feature(label, feature)
	return function()
		local filter = { bufnr = 0 }
		local enabled = not feature.is_enabled(filter)
		feature.enable(enabled, filter)
		vim.notify(label .. " " .. (enabled and "enabled" or "disabled"))
	end
end

function M.setup()
	vim.api.nvim_create_user_command(
		"LspInlayHintsToggle",
		toggle_feature("Inlay hints", vim.lsp.inlay_hint),
		{ force = true, desc = "Toggle LSP inlay hints for the current buffer" }
	)
	vim.api.nvim_create_user_command(
		"LspSemanticTokensToggle",
		toggle_feature("Semantic tokens", vim.lsp.semantic_tokens),
		{ force = true, desc = "Toggle LSP semantic tokens for the current buffer" }
	)
	vim.api.nvim_create_user_command("DiagnosticMode", function()
		diagnostic_mode = diagnostic_mode % #diagnostic_modes + 1
		local mode = diagnostic_modes[diagnostic_mode]
		vim.diagnostic.config(mode.config)
		vim.notify("Diagnostics: " .. mode.name)
	end, { force = true, desc = "Cycle diagnostics through virtual text, virtual lines, and signs only" })

	vim.keymap.set("n", "<leader>ti", "<cmd>LspInlayHintsToggle<CR>", { desc = "Toggle inlay hints" })
	vim.keymap.set("n", "<leader>tS", "<cmd>LspSemanticTokensToggle<CR>", { desc = "Toggle semantic tokens" })
	vim.keymap.set("n", "<leader>dv", "<cmd>DiagnosticMode<CR>", { desc = "Cycle diagnostic display" })
end

return M
