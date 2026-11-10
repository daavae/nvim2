local M = type(package.loaded["config.terminal"]) == "table" and package.loaded["config.terminal"] or {}
M.state = M.state or {}
local state = M.state
state.items = state.items or {}
state.panels = state.panels or {}
state.next_id = state.next_id or 0
state.position = state.position or "bottom"

local function find(id)
	for index, item in ipairs(state.items) do
		if item.id == id then
			return item, index
		end
	end
end

local function panel()
	local tab = vim.api.nvim_get_current_tabpage()
	state.panels[tab] = state.panels[tab] or {}
	return state.panels[tab]
end

local function resize(win)
	if state.position == "right" then
		vim.api.nvim_win_set_width(win, math.max(20, math.floor(vim.o.columns * 0.4)))
	else
		vim.api.nvim_win_set_height(win, math.max(1, math.min(12, math.floor((vim.o.lines - vim.o.cmdheight - 2) / 4))))
	end
end

local function refresh()
	local parts = {}
	for _, item in ipairs(state.items) do
		local name = item.id .. ":" .. vim.fn.fnamemodify(vim.o.shell, ":t")
		if item.exit_code ~= nil then
			name = name .. " (exit " .. item.exit_code .. ")"
		end
		parts[#parts + 1] = "%" .. item.id .. "@v:lua.TerminalPanelClick@ " .. name:gsub("%%", "%%%%") .. " %X"
	end
	parts[#parts + 1] = "%0@v:lua.TerminalPanelClick@ + %X"
	for tab, view in pairs(state.panels) do
		if not vim.api.nvim_tabpage_is_valid(tab) then
			state.panels[tab] = nil
		elseif view.win and vim.api.nvim_win_is_valid(view.win) then
			local active = vim.b[vim.api.nvim_win_get_buf(view.win)].panel_terminal_id
			local tabs = {}
			for index, item in ipairs(state.items) do
				tabs[index] = (item.id == active and "%#TabLineSel#" or "%#TabLine#") .. parts[index]
			end
			tabs[#tabs + 1] = "%#TabLine#" .. parts[#parts]
			vim.wo[view.win].winbar = table.concat(tabs)
		end
	end
end

-- Remember where a terminal was scrolled to, unless it was at the bottom following output.
local function remember(win)
	local item = find(vim.b[vim.api.nvim_win_get_buf(win)].panel_terminal_id)
	if item then
		local following = vim.fn.line("w$", win) >= vim.fn.line("$", win)
		item.view = not following and vim.api.nvim_win_call(win, vim.fn.winsaveview) or nil
	end
end

local function hide(view)
	view = view or panel()
	vim.cmd("stopinsert")
	local focused = view.win and vim.api.nvim_get_current_win() == view.win
	if view.win and vim.api.nvim_win_is_valid(view.win) then
		remember(view.win)
		if #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(view.win)) == 1 then
			vim.api.nvim_win_set_buf(view.win, vim.api.nvim_create_buf(true, false))
			vim.wo[view.win].winbar = ""
			vim.wo[view.win].winfixheight, vim.wo[view.win].winfixwidth = false, false
		else
			vim.api.nvim_win_close(view.win, true)
		end
	end
	view.win = nil
	if focused and view.origin and vim.api.nvim_win_is_valid(view.origin) then
		vim.api.nvim_set_current_win(view.origin)
	end
end

local function show(item, insert)
	local view = panel()
	local current = vim.api.nvim_get_current_win()
	if current ~= view.win and vim.api.nvim_win_get_config(current).relative == "" then
		view.origin = current
	end
	if not view.win or not vim.api.nvim_win_is_valid(view.win) then
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if vim.api.nvim_win_get_config(win).relative == "" then
				vim.api.nvim_set_current_win(win)
				break
			end
		end
		local right = state.position == "right"
		vim.cmd(right and "botright vsplit" or "botright split")
		view.win = vim.api.nvim_get_current_win()
		vim.wo[view.win].winfixheight, vim.wo[view.win].winfixwidth = not right, right
		resize(view.win)
	else
		vim.api.nvim_set_current_win(view.win)
		if vim.api.nvim_win_get_buf(view.win) ~= item.buf then
			remember(view.win)
		end
	end
	state.active, view.active = item.id, item.id
	vim.api.nvim_win_set_buf(view.win, item.buf)
	vim.wo[view.win].number, vim.wo[view.win].relativenumber, vim.wo[view.win].signcolumn = false, false, "no"
	refresh()
	if item.view then
		-- Reopen at the saved scroll position in normal mode; insert mode would jump to the bottom.
		vim.fn.winrestview(item.view)
	elseif insert ~= false then
		vim.cmd("startinsert")
	end
end

function M.new()
	state.next_id = state.next_id + 1
	local item = { id = state.next_id, buf = vim.api.nvim_create_buf(false, true) }
	vim.bo[item.buf].bufhidden = "hide"
	vim.b[item.buf].panel_terminal_id = item.id
	state.items[#state.items + 1] = item
	show(item)
	item.job = vim.fn.jobstart({ vim.o.shell }, {
		term = true,
		cwd = vim.fn.getcwd(),
	})
	if item.job <= 0 then
		M.close(item.id)
		vim.notify("Could not start the terminal shell", vim.log.levels.ERROR)
	end
end

function M.toggle()
	local view = panel()
	if view.win and vim.api.nvim_win_is_valid(view.win) then
		hide(view)
	else
		local item = find(view.active or state.active) or state.items[1]
		if item then
			show(item)
		else
			M.new()
		end
	end
end

function M.move(position)
	state.position = position or (state.position == "right" and "bottom" or "right")
	local view = panel()
	local item = find(view.active or state.active)
	if not (item and view.win and vim.api.nvim_win_is_valid(view.win)) then
		return
	end
	-- Reopening the panel would jump the terminal to its bottom and reflow the other
	-- windows, so save every view (and the focused window) and put them back afterwards.
	local current = vim.api.nvim_get_current_win()
	local term_view = vim.api.nvim_win_call(view.win, vim.fn.winsaveview)
	local views = {}
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if win ~= view.win and vim.api.nvim_win_get_config(win).relative == "" then
			views[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
		end
	end
	local term_focused = current == view.win
	hide(view)
	show(item, false)
	vim.api.nvim_win_call(view.win, function()
		vim.fn.winrestview(term_view)
	end)
	for win, saved in pairs(views) do
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_call(win, function()
				vim.fn.winrestview(saved)
			end)
		end
	end
	if not term_focused and vim.api.nvim_win_is_valid(current) then
		vim.api.nvim_set_current_win(current)
	end
end

function M.cycle(direction)
	local _, index = find(panel().active or state.active)
	if #state.items > 0 then
		show(state.items[((index or 1) - 1 + direction) % #state.items + 1])
	else
		M.new()
	end
end

function M.select()
	local choices = vim.list_extend({ { new = true } }, vim.list_slice(state.items))
	vim.ui.select(choices, {
		prompt = "Terminals",
		format_item = function(item)
			return item.new and "+ New terminal"
				or ("Terminal %d%s"):format(item.id, item.exit_code and " (exited)" or "")
		end,
	}, function(item)
		if item then
			if item.new then
				M.new()
			elseif find(item.id) then
				show(item)
			end
		end
	end)
end

function M.close(id)
	local item, index = find(id or panel().active or state.active)
	if not item then
		return
	end
	table.remove(state.items, index)
	local replacement = state.items[math.min(index, #state.items)]
	if state.active == item.id then
		state.active = replacement and replacement.id or nil
	end
	for _, view in pairs(state.panels) do
		local selected = view.active == item.id
		if selected then
			view.active = replacement and replacement.id or nil
		end
		if
			view.win
			and vim.api.nvim_win_is_valid(view.win)
			and (selected or vim.api.nvim_win_get_buf(view.win) == item.buf)
		then
			if replacement then
				vim.api.nvim_win_set_buf(view.win, replacement.buf)
			else
				hide(view)
			end
		end
	end
	if item.job and item.job > 0 then
		vim.fn.jobstop(item.job)
	end
	if vim.api.nvim_buf_is_valid(item.buf) then
		vim.api.nvim_buf_delete(item.buf, { force = true })
	end
	refresh()
end

function M.setup(smart_navigate)
	local group = vim.api.nvim_create_augroup("UserConfigTerminal", { clear = true })
	local function request_extended_keys()
		if vim.env.TMUX and #vim.api.nvim_list_uis() > 0 then
			-- tmux needs an application request to distinguish Ctrl+` from NUL.
			vim.api.nvim_chan_send(vim.v.stderr, "\27[>4;2m")
		end
	end
	vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, { group = group, callback = request_extended_keys })
	request_extended_keys()
	-- Adopt a shell opened by the previous floating-terminal setup without restarting it.
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) and vim.bo[state.buf].buftype == "terminal" then
		state.next_id = state.next_id + 1
		state.items[#state.items + 1] = { id = state.next_id, buf = state.buf, job = vim.b[state.buf].terminal_job_id }
		vim.b[state.buf].floating_terminal = nil
		vim.b[state.buf].panel_terminal_id = state.next_id
		state.active = state.next_id
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_close(state.win, true)
		end
		state.buf, state.win, state.is_open = nil, nil, nil
	end
	local function attach(buf)
		if vim.b[buf].panel_terminal_id then
			vim.keymap.set({ "n", "t" }, "<C-PageUp>", function()
				M.cycle(-1)
			end, { buffer = buf, desc = "Previous terminal" })
			vim.keymap.set({ "n", "t" }, "<C-PageDown>", function()
				M.cycle(1)
			end, { buffer = buf, desc = "Next terminal" })
		end
		vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = buf, desc = "Send escape" })
		for key, directions in pairs({ h = { "h", "-L" }, j = { "j", "-D" }, k = { "k", "-U" }, l = { "l", "-R" } }) do
			vim.keymap.set("t", "<C-" .. key .. ">", function()
				vim.api.nvim_feedkeys(vim.keycode("<C-\\><C-n>"), "n", false)
				vim.schedule(function()
					smart_navigate("wincmd " .. directions[1], directions[2])
				end)
			end, { buffer = buf, desc = "Navigate " .. key })
		end
	end
	vim.api.nvim_create_autocmd("TermOpen", {
		group = group,
		callback = function(args)
			vim.wo.number, vim.wo.relativenumber, vim.wo.signcolumn = false, false, "no"
			attach(args.buf)
		end,
	})
	vim.api.nvim_create_autocmd("TermClose", {
		group = group,
		callback = function(args)
			local id = vim.api.nvim_buf_is_valid(args.buf) and vim.b[args.buf].panel_terminal_id
			local code = vim.v.event.status
			if id then
				vim.schedule(function()
					local item = find(id)
					if item then
						item.exit_code, item.job = code, nil
						refresh()
					end
				end)
			end
		end,
	})
	vim.api.nvim_create_autocmd("VimResized", {
		group = group,
		callback = function()
			vim.defer_fn(function()
				for _, view in pairs(state.panels) do
					if view.win and vim.api.nvim_win_is_valid(view.win) then
						resize(view.win)
					end
				end
			end, 30)
		end,
	})
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(args)
			for _, view in pairs(state.panels) do
				if view.win == tonumber(args.match) then
					view.win = nil
				end
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			local id = vim.b[args.buf].panel_terminal_id
			if id and find(id) then
				vim.schedule(function()
					M.close(id)
				end)
			end
		end,
	})
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.bo[buf].buftype == "terminal" then
			attach(buf)
		end
	end
	_G.TerminalPanelClick = function(id)
		if id == 0 then
			M.new()
		elseif find(id) then
			show(find(id))
		end
	end
	vim.keymap.set({ "n", "i", "t" }, "<C-`>", M.toggle, { desc = "Toggle terminal panel" })
	vim.keymap.set({ "n", "i", "t" }, "<C-S-`>", M.new, { desc = "New panel terminal" })
	vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle terminal panel" })
	vim.keymap.set("n", "<leader>tm", function()
		M.move()
	end, { desc = "Move terminal panel (bottom/right)" })
	vim.api.nvim_create_user_command("TerminalMove", function(args)
		M.move(args.args ~= "" and args.args or nil)
	end, {
		force = true,
		nargs = "?",
		complete = function()
			return { "bottom", "right" }
		end,
		desc = "Move the terminal panel to the bottom or right",
	})
	vim.api.nvim_create_user_command(
		"TerminalNew",
		M.new,
		{ force = true, desc = "Create a shell in the terminal panel" }
	)
	vim.api.nvim_create_user_command(
		"Terminals",
		M.select,
		{ force = true, desc = "Select or create a panel terminal" }
	)
	vim.api.nvim_create_user_command("TerminalNext", function()
		M.cycle(1)
	end, { force = true })
	vim.api.nvim_create_user_command("TerminalPrev", function()
		M.cycle(-1)
	end, { force = true })
	vim.api.nvim_create_user_command("TerminalClose", function()
		M.close()
	end, { force = true })
	for _, view in pairs(state.panels) do
		if view.win and vim.api.nvim_win_is_valid(view.win) then
			resize(view.win)
		end
	end
	refresh()
end

return M
