local M = {}

local function tabpage_label(tabpage, index)
	local ok, name = pcall(vim.api.nvim_tabpage_get_var, tabpage, "tab_name")
	if ok and type(name) == "string" and name ~= "" then
		return name
	end

	local win = vim.api.nvim_tabpage_get_win(tabpage)
	local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
	if bufname ~= "" then
		return vim.fn.fnamemodify(bufname, ":t")
	end
	return "Tab " .. tostring(index)
end

local function render()
	local current = vim.api.nvim_get_current_tabpage()
	local parts = {}
	for i, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
		local hl = tabpage == current and "%#TabLineSel#" or "%#TabLine#"
		local label = tabpage_label(tabpage, i):gsub("%%", "%%%%")
		table.insert(parts, hl .. "%" .. i .. "T" .. " " .. i .. ":" .. label .. " ")
	end
	table.insert(parts, "%#TabLineFill#%T")
	return table.concat(parts, "")
end

function M.setup()
	_G.CUSTOM_TABLINE = render
	vim.o.showtabline = 2
	vim.o.tabline = "%!v:lua.CUSTOM_TABLINE()"

	vim.api.nvim_create_user_command("TabRename", function(opts)
		vim.api.nvim_tabpage_set_var(0, "tab_name", opts.args)
		vim.cmd("redrawtabline")
	end, { nargs = 1, force = true })
	vim.api.nvim_create_user_command("TabRenameClear", function()
		pcall(vim.api.nvim_tabpage_del_var, 0, "tab_name")
		vim.cmd("redrawtabline")
	end, { nargs = 0, force = true })

	vim.keymap.set("n", "<leader>tr", function()
		local ok, current = pcall(vim.api.nvim_tabpage_get_var, 0, "tab_name")
		vim.ui.input({ prompt = "Tab name: ", default = ok and current or "" }, function(input)
			if input == nil then
				return
			end
			if input == "" then
				pcall(vim.api.nvim_tabpage_del_var, 0, "tab_name")
			else
				vim.api.nvim_tabpage_set_var(0, "tab_name", input)
			end
			vim.cmd("redrawtabline")
		end)
	end, { desc = "Rename tab" })
	vim.keymap.set("n", "<leader>tc", function()
		pcall(vim.api.nvim_tabpage_del_var, 0, "tab_name")
		vim.cmd("redrawtabline")
	end, { desc = "Clear tab name" })
end

return M
