local M = {}

local function can_persist_view(buf)
	return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

function M.setup()
	local group = vim.api.nvim_create_augroup("UserConfigViews", { clear = true })
	-- Autoread needs an explicit check to notice external changes.
	vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
		group = group,
		desc = "Check for external file changes",
		callback = function()
			if vim.bo.buftype == "" then
				vim.cmd("checktime")
			end
		end,
	})
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = group,
		callback = function()
			vim.hl.on_yank()
		end,
	})
	vim.api.nvim_create_autocmd("BufWinLeave", {
		group = group,
		desc = "Save folds and cursor view",
		callback = function(args)
			if can_persist_view(args.buf) then
				vim.cmd("silent! mkview")
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = group,
		desc = "Restore folds and cursor view",
		callback = function(args)
			if can_persist_view(args.buf) then
				vim.cmd("silent! loadview")
			end
		end,
	})
	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		desc = "Rebalance windows after terminal resize",
		callback = function()
			vim.defer_fn(function()
				pcall(function()
					local current_tab = vim.api.nvim_get_current_tabpage()
					vim.cmd("tabdo wincmd =")
					if vim.api.nvim_tabpage_is_valid(current_tab) then
						vim.api.nvim_set_current_tabpage(current_tab)
					end
				end)
			end, 20)
		end,
	})
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		desc = "Restore last cursor position",
		callback = function()
			if vim.o.diff then
				return
			end
			local last_pos = vim.api.nvim_buf_get_mark(0, '"')
			local row = last_pos[1]
			if row < 1 or row > vim.api.nvim_buf_line_count(0) then
				return
			end
			pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
		end,
	})
end

return M
