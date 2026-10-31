local M = {}

function M.get(buf, position)
	buf = buf or vim.api.nvim_get_current_buf()
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "json")
	if not ok then
		return ""
	end
	local trees = parser:parse()
	if not trees[1] then
		return ""
	end
	position = position or vim.api.nvim_win_get_cursor(0)
	local row, col = position[1] - 1, position[2]
	local node = trees[1]:root():named_descendant_for_range(row, col, row, col)
	local parts = {}
	while node do
		local parent = node:parent()
		if parent and parent:type() == "pair" then
			local key_node = parent:field("key")[1]
			if not key_node then
				return ""
			end
			local decoded, key = pcall(vim.json.decode, vim.treesitter.get_node_text(key_node, buf))
			if not decoded or type(key) ~= "string" then
				return ""
			end
			local accessor = key:match("^[A-Za-z_][A-Za-z0-9_]*$") and "." .. key or "[" .. vim.json.encode(key) .. "]"
			table.insert(parts, 1, accessor)
		elseif parent and parent:type() == "array" then
			local index = 0
			for child in parent:iter_children() do
				if child:named() and child:type() ~= "comment" then
					if child:id() == node:id() then
						table.insert(parts, 1, "[" .. index .. "]")
						break
					end
					index = index + 1
				end
			end
		end
		node = parent
	end
	local path = table.concat(parts)
	return path:sub(1, 1) == "[" and "." .. path or (path ~= "" and path or ".")
end

function M.setup()
	vim.keymap.set("n", "<leader>jp", function()
		print(M.get())
	end, { desc = "Show JSON path" })
	vim.keymap.set("n", "<leader>jy", function()
		local path = M.get()
		vim.fn.setreg("+", path)
		print("copied:", path)
	end, { desc = "Yank JSON path to clipboard" })
	_G.JSON_WINBAR = function()
		if vim.bo.filetype ~= "json" then
			return ""
		end
		local path = M.get()
		return path ~= "" and (" " .. path) or ""
	end
	local function set_winbar()
		vim.wo.winbar = vim.bo.filetype == "json" and "%{%v:lua.JSON_WINBAR()%}" or ""
	end
	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = vim.api.nvim_create_augroup("UserConfigJson", { clear = true }),
		callback = set_winbar,
	})
	set_winbar()
end

return M
