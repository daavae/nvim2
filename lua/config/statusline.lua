local M = {}

function M.setup()
	require("mini.statusline").setup({})
	vim.go.statusline = vim.go.statusline .. "%{v:lua.format_status()}"
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		vim.wo[win].statusline = ""
	end
end

return M
