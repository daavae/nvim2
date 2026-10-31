local M = {}

function M.setup(plugins)
	local function smart_open(selected, opts)
		local actions = plugins.get_fzf_actions()
		if not actions or not selected or #selected == 0 then
			return
		end
		actions.file_edit({ selected[1] }, opts)
		if #selected > 1 then
			actions.file_tabedit(vim.list_slice(selected, 2), opts)
		end
	end

	vim.keymap.set("n", "<leader>fg", function()
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.live_grep()
		end
	end, { desc = "FZF Live Grep" })
	vim.keymap.set("n", "<leader>fb", function()
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.buffers()
		end
	end, { desc = "FZF Buffers" })
	vim.keymap.set("n", "<leader>fh", function()
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.help_tags()
		end
	end, { desc = "FZF Help Tags" })
	vim.keymap.set("n", "<leader>fk", function()
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.keymaps()
		end
	end, { desc = "FZF Keymaps" })
	vim.keymap.set("n", "<leader>fm", function()
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.marks()
		end
	end, { desc = "FZF Marks" })
	vim.keymap.set("n", "<leader>ff", function()
		local fzf = plugins.get_fzf()
		local actions = plugins.get_fzf_actions()
		if not (fzf and actions) then
			return
		end
		fzf.files({
			fzf_opts = { ["--multi"] = true },
			actions = { ["default"] = smart_open, ["ctrl-t"] = actions.file_tabedit },
		})
	end, { desc = "FZF Files" })
	vim.keymap.set("n", "<leader>fx", function()
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.diagnostics_document()
		end
	end, { desc = "FZF Diagnostics Document" })
	vim.keymap.set("n", "<leader>fX", function()
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.diagnostics_workspace()
		end
	end, { desc = "FZF Diagnostics Workspace" })
end

return M
