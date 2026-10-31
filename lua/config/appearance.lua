local M = {}

local function highlights()
	vim.api.nvim_set_hl(0, "Cursor", { fg = "#1a1b26", bg = "#7dcfff" })
	vim.api.nvim_set_hl(0, "CursorIM", { fg = "#1a1b26", bg = "#9ece6a" })
	vim.api.nvim_set_hl(0, "lCursor", { fg = "#1a1b26", bg = "#7dcfff" })
	vim.api.nvim_set_hl(0, "MatchParen", { fg = "#bb9af7", bg = "NONE", bold = true, underline = true })
	vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
		fg = "#ff9e64",
		bg = "NONE",
		bold = true,
		undercurl = true,
		sp = "#ff9e64",
	})
end

function M.setup()
	if not pcall(vim.cmd.colorscheme, "tokyonight-moon") then
		vim.notify("tokyonight-moon unavailable, falling back to habamax", vim.log.levels.WARN)
		vim.cmd.colorscheme("habamax")
	end
	highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("UserConfigAppearance", { clear = true }),
		callback = highlights,
	})
end

return M
