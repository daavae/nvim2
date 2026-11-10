local M = {}

local project_filename = ".todo.md"
local global_todo = vim.fn.stdpath("data") .. "/todo/global.md"

local function trim(value)
	return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function current_directory()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" or name == global_todo then
		return vim.fn.getcwd()
	end
	if vim.fn.isdirectory(name) == 1 then
		return name
	end
	return vim.fs.dirname(name) or vim.fn.getcwd()
end

local function git_output(root, ...)
	local command = { "git", "-C", root }
	vim.list_extend(command, { ... })
	local result = vim.system(command, { text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	return trim(result.stdout)
end

local function project_root()
	return git_output(current_directory(), "rev-parse", "--show-toplevel")
end

local function ensure_line(path, line)
	local lines = {}
	if vim.uv.fs_stat(path) then
		lines = vim.fn.readfile(path)
	end
	if vim.tbl_contains(lines, line) then
		return true
	end

	vim.fn.mkdir(vim.fs.dirname(path), "p")
	lines[#lines + 1] = line
	local ok, err = pcall(vim.fn.writefile, lines, path)
	if not ok then
		vim.notify("Could not update Git exclude file: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
	return true
end

local function exclude_project_todo(root)
	local exclude_path = git_output(root, "rev-parse", "--git-path", "info/exclude")
	if not exclude_path then
		return false
	end
	if not vim.startswith(exclude_path, "/") then
		exclude_path = vim.fs.joinpath(root, exclude_path)
	end
	return ensure_line(exclude_path, project_filename)
end

local function attach_markview(buf)
	if not require("config.plugins").get_markview() then
		return
	end

	local state = require("markview.state")
	if not state.buf_attached(buf) then
		require("markview.actions").attach(buf)
	end
end

local function todo_window(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
			local config = vim.api.nvim_win_get_config(win)
			if config.relative and config.relative ~= "" then
				return win
			end
		end
	end
end

local function close_todo(win, buf)
	if vim.bo[buf].modified then
		local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
			vim.cmd("silent write")
		end)
		if not ok then
			vim.notify("Could not save todo list: " .. tostring(err), vim.log.levels.ERROR)
			return
		end
	end
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

local function open_todo_float(buf, title)
	local existing = todo_window(buf)
	if existing then
		vim.api.nvim_set_current_win(existing)
		return existing
	end

	local width = math.max(1, math.floor(vim.o.columns * 0.8))
	local height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight) * 0.8))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
		title_pos = "center",
	})

	vim.wo[win].winblend = 0
	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.wo[win].cursorline = true
	vim.wo[win].signcolumn = "no"
	vim.wo[win].colorcolumn = ""

	vim.keymap.set("n", "Q", function()
		close_todo(win, buf)
	end, { buffer = buf, silent = true, desc = "Save and close todo list" })

	return win
end

local function open_todo(path, title)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	if not vim.uv.fs_stat(path) then
		vim.fn.writefile({ "# " .. title, "", "- [ ] " }, path)
	end

	local buf = vim.fn.bufadd(path)
	vim.fn.bufload(buf)
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].filetype = "markdown"
	vim.b[buf].todo_list = true
	vim.keymap.set("n", "<leader>tx", M.toggle_checkbox, {
		buffer = buf,
		silent = true,
		desc = "Toggle todo checkbox",
	})
	open_todo_float(buf, title)
	attach_markview(buf)
end

function M.open_project()
	local root = project_root()
	if not root then
		vim.notify("Project todo requires a Git repository", vim.log.levels.WARN)
		return
	end
	if not exclude_project_todo(root) then
		return
	end

	local project_name = vim.fn.fnamemodify(root, ":t")
	open_todo(vim.fs.joinpath(root, project_filename), project_name .. " TODO")
end

function M.open_global()
	open_todo(global_todo, "Global TODO")
end

function M.toggle_checkbox()
	if not require("config.plugins").get_markview() then
		return
	end
	local buf = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	require("markview.extras.checkboxes").toggler.init(buf, row - 1, row)
end

local function highlight()
	vim.api.nvim_set_hl(0, "Todo", { fg = "#080808", bg = "#e3c78a", bold = true })
end

function M.setup()
	local group = vim.api.nvim_create_augroup("UserConfigTodo", { clear = true })
	highlight()
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlight })
	vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
		group = group,
		callback = function(args)
			if vim.bo[args.buf].buftype ~= "" or vim.w.__todo_match_id ~= nil then
				return
			end
			vim.w.__todo_match_id =
				vim.fn.matchadd("Todo", [[\v<(TODO|FIXME|HACK|NOTE|BUG|XXX|OPTIMIZE|PERF)>\s*:?]], 100)
		end,
	})
	vim.api.nvim_create_user_command("TodoProject", M.open_project, {
		force = true,
		desc = "Open this Git project's private todo list",
	})
	vim.api.nvim_create_user_command("TodoGlobal", M.open_global, {
		force = true,
		desc = "Open the global todo list",
	})
	vim.api.nvim_create_user_command("TodoToggle", M.toggle_checkbox, {
		force = true,
		desc = "Toggle the checkbox on the current line",
	})

	vim.keymap.set("n", "<leader>tp", M.open_project, { desc = "Open project todo" })
	vim.keymap.set("n", "<leader>tg", M.open_global, { desc = "Open global todo" })
	vim.keymap.set("n", "<leader>tx", M.toggle_checkbox, { desc = "Toggle todo checkbox" })
end

return M
