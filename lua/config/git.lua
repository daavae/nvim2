local M = type(package.loaded["config.git"]) == "table" and package.loaded["config.git"] or {}
M.popup = M.popup or {}
local popup = M.popup

local function window_config()
	local width = math.max(1, math.min(math.floor(vim.o.columns * 0.9), vim.o.columns - 2))
	local height = math.max(1, math.min(math.floor(vim.o.lines * 0.9), vim.o.lines - vim.o.cmdheight - 3))
	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
		style = "minimal",
		border = "rounded",
		title = " LazyGit ",
		title_pos = "center",
	}
end

local function finish(buf, code)
	if popup.buf ~= buf then
		return
	end
	local restore_focus = popup.win and vim.api.nvim_get_current_win() == popup.win
	if popup.win and vim.api.nvim_win_is_valid(popup.win) then
		vim.api.nvim_win_close(popup.win, true)
	end
	if restore_focus and popup.origin and vim.api.nvim_win_is_valid(popup.origin) then
		vim.api.nvim_set_current_win(popup.origin)
	end
	popup.buf, popup.win, popup.job = nil, nil, nil
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_delete(buf, { force = true })
	end
	vim.cmd("checktime")
	if code ~= 0 then
		vim.notify("LazyGit exited with code " .. code, vim.log.levels.WARN)
	end
end

local function open()
	if popup.win and vim.api.nvim_win_is_valid(popup.win) then
		vim.api.nvim_set_current_win(popup.win)
		vim.cmd("startinsert")
		return
	end
	if vim.fn.executable("lazygit") ~= 1 then
		vim.notify("Install the lazygit executable to use the Git popup", vim.log.levels.ERROR)
		return
	end
	if not popup.buf or not vim.api.nvim_buf_is_valid(popup.buf) then
		local path = vim.api.nvim_buf_get_name(0)
		local dir = path ~= "" and not path:find("://", 1, true) and vim.fs.dirname(path) or vim.fn.getcwd()
		local result = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
		if result.code ~= 0 then
			vim.notify("LazyGit requires a Git repository", vim.log.levels.WARN)
			return
		end
		popup.root = vim.trim(result.stdout)
		popup.buf = vim.api.nvim_create_buf(false, true)
		vim.bo[popup.buf].bufhidden = "hide"
	end
	popup.origin = vim.api.nvim_get_current_win()
	popup.win = vim.api.nvim_open_win(popup.buf, true, window_config())
	vim.wo[popup.win].winblend = 0
	if not popup.job then
		local buf = popup.buf
		local job = vim.fn.jobstart({ "lazygit", "-p", popup.root }, {
			term = true,
			cwd = popup.root,
			on_exit = function(_, code)
				vim.schedule(function()
					finish(buf, code)
				end)
			end,
		})
		if job <= 0 then
			finish(buf, job)
			return
		end
		popup.job = job
		vim.bo[buf].filetype = "lazygit"
	end
	vim.cmd("startinsert")
end

function M.setup()
	local blame = package.loaded["gitsigns.config"] and require("gitsigns.config").config.current_line_blame
	require("gitsigns").setup({
		signs = {
			add = { text = "\u{2590}" },
			change = { text = "\u{2590}" },
			delete = { text = "\u{2590}" },
			topdelete = { text = "\u{25e6}" },
			changedelete = { text = "\u{25cf}" },
			untracked = { text = "\u{25cb}" },
		},
		signcolumn = true,
		current_line_blame = blame or false,
	})
	vim.keymap.set("n", "]h", function()
		require("gitsigns").next_hunk()
	end, { desc = "Next git hunk" })
	vim.keymap.set("n", "[h", function()
		require("gitsigns").prev_hunk()
	end, { desc = "Previous git hunk" })
	vim.keymap.set("n", "<leader>gs", function()
		require("gitsigns").stage_hunk()
	end, { desc = "Stage hunk" })
	vim.keymap.set("n", "<leader>gr", function()
		require("gitsigns").reset_hunk()
	end, { desc = "Reset hunk" })
	vim.keymap.set("n", "<leader>gP", function()
		require("gitsigns").preview_hunk()
	end, { desc = "Preview hunk" })
	vim.keymap.set("n", "<leader>gb", function()
		require("gitsigns").blame_line({ full = true })
	end, { desc = "Blame line" })
	vim.keymap.set("n", "<leader>gB", function()
		require("gitsigns").toggle_current_line_blame()
	end, { desc = "Toggle inline blame" })
	vim.keymap.set("n", "<leader>gD", function()
		require("gitsigns").diffthis()
	end, { desc = "Diff this" })
	local group = vim.api.nvim_create_augroup("UserConfigGit", { clear = true })
	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		callback = function()
			if popup.win and vim.api.nvim_win_is_valid(popup.win) then
				vim.api.nvim_win_set_config(popup.win, window_config())
			end
		end,
	})
	vim.api.nvim_create_user_command("LazyGit", open, { force = true, desc = "Open LazyGit in a terminal popup" })
	vim.keymap.set("n", "<leader>gg", open, { desc = "Open LazyGit" })
end

return M
