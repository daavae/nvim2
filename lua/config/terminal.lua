local M = {}
local state = { buf = nil, win = nil, is_open = false }

local function close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, false)
	end
	state.win = nil
	state.is_open = false
end

local function toggle()
	if state.is_open and state.win and vim.api.nvim_win_is_valid(state.win) then
		close()
		return
	end

	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		state.buf = vim.api.nvim_create_buf(false, true)
		vim.bo[state.buf].bufhidden = "hide"
		vim.b[state.buf].floating_terminal = true
	end

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	state.win = vim.api.nvim_open_win(state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
	})

	vim.wo[state.win].winblend = 0
	vim.wo[state.win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"

	if vim.bo[state.buf].buftype ~= "terminal" then
		vim.fn.jobstart({ vim.o.shell }, { term = true })
	end

	state.is_open = true
	vim.cmd("startinsert")
	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = state.buf,
		once = true,
		callback = close,
	})
end

function M.setup(smart_navigate)
	local group = vim.api.nvim_create_augroup("UserConfigTerminal", { clear = true })
	vim.api.nvim_create_autocmd("TermOpen", {
		group = group,
		callback = function()
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.signcolumn = "no"
			vim.keymap.set("t", "<Esc>", "<Esc>", {
				buffer = true,
				noremap = true,
				silent = true,
				desc = "Send escape",
			})

			local function navigate(wincmd, tmux_flag)
				vim.api.nvim_feedkeys(vim.keycode("<C-\\><C-n>"), "n", false)
				vim.schedule(function()
					smart_navigate(wincmd, tmux_flag)
				end)
			end
			vim.keymap.set("t", "<C-h>", function()
				navigate("wincmd h", "-L")
			end, { buffer = true, silent = true, desc = "Navigate left" })
			vim.keymap.set("t", "<C-j>", function()
				navigate("wincmd j", "-D")
			end, { buffer = true, silent = true, desc = "Navigate down" })
			vim.keymap.set("t", "<C-k>", function()
				navigate("wincmd k", "-U")
			end, { buffer = true, silent = true, desc = "Navigate up" })
			vim.keymap.set("t", "<C-l>", function()
				navigate("wincmd l", "-R")
			end, { buffer = true, silent = true, desc = "Navigate right" })
		end,
	})

	vim.api.nvim_create_autocmd("TermClose", {
		group = group,
		pattern = "term://*",
		callback = function(args)
			if vim.b[args.buf].floating_terminal ~= true then
				return
			end
			if args.buf == state.buf then
				state.buf = nil
				state.win = nil
				state.is_open = false
			end
			vim.schedule(function()
				pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
			end)
		end,
	})

	vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none" })
	vim.keymap.set("n", "<leader>tt", toggle, { silent = true, desc = "Toggle floating terminal" })
end

return M
