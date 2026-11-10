local M = {}

local function highlights()
	vim.api.nvim_set_hl(0, "Cursor", { fg = "#080808", bg = "#79dac8" })
	vim.api.nvim_set_hl(0, "CursorIM", { fg = "#080808", bg = "#8cc85f" })
	vim.api.nvim_set_hl(0, "lCursor", { fg = "#080808", bg = "#79dac8" })
	vim.api.nvim_set_hl(0, "MatchParen", { fg = "#cf87e8", bg = "NONE", bold = true, underline = true })
	vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
		fg = "#de935f",
		bg = "NONE",
		bold = true,
		undercurl = true,
		sp = "#de935f",
	})
end

function M.setup()
	-- Let the black background set by tmux show through.
	vim.g.moonflyTransparent = true
	if not pcall(vim.cmd.colorscheme, "moonfly") then
		vim.notify("moonfly unavailable, falling back to habamax", vim.log.levels.WARN)
		vim.cmd.colorscheme("habamax")
	end
	highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("UserConfigAppearance", { clear = true }),
		callback = highlights,
	})
end

return M
