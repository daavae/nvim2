local M = {}

local function fold_aware_paragraph(key, forward)
	return function()
		vim.cmd.normal({ key, bang = true })
		local line = vim.fn.line(".")
		local fold_start = vim.fn.foldclosed(line)
		if fold_start == -1 then
			return
		end
		local target = forward and math.min(vim.fn.foldclosedend(line) + 1, vim.api.nvim_buf_line_count(0))
			or math.max(fold_start - 1, 1)
		vim.api.nvim_win_set_cursor(0, { target, 0 })
	end
end

local function jump_closed_fold(forward)
	return function()
		local last = vim.api.nvim_buf_line_count(0)
		local step = forward and 1 or -1
		local target = vim.fn.line(".") + step
		while target >= 1 and target <= last do
			local fold_start = vim.fn.foldclosed(target)
			if fold_start ~= -1 then
				vim.api.nvim_win_set_cursor(0, { fold_start, 0 })
				return
			end
			target = target + step
		end
	end
end

function M.smart_navigate(wincmd, tmux_flag)
	local before = vim.api.nvim_get_current_win()
	vim.cmd(wincmd)
	if vim.api.nvim_get_current_win() ~= before or not vim.env.TMUX or vim.env.TMUX == "" then
		return
	end
	vim.system({ "tmux", "select-pane", "-Z", tmux_flag })
end

function M.setup()
	vim.keymap.set("n", "j", function()
		return vim.v.count == 0 and "gj" or "j"
	end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
	vim.keymap.set("n", "k", function()
		return vim.v.count == 0 and "gk" or "k"
	end, { expr = true, silent = true, desc = "Up (wrap-aware)" })
	vim.keymap.set("i", "jk", "<Esc>", { desc = "jk binded to be esc key to go into normal mode" })
	vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
	vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
	vim.keymap.set("n", "<C-d>", "<C-d>", { desc = "Half page down" })
	vim.keymap.set("n", "<C-u>", "<C-u>", { desc = "Half page up" })
	vim.keymap.set("n", "}", fold_aware_paragraph("}", true), { desc = "Next paragraph (skip folds)" })
	vim.keymap.set("n", "{", fold_aware_paragraph("{", false), { desc = "Previous paragraph (skip folds)" })
	vim.keymap.set("n", "]z", jump_closed_fold(true), { desc = "Next closed fold" })
	vim.keymap.set("n", "[z", jump_closed_fold(false), { desc = "Previous closed fold" })
	vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlighing with <Esc>" })
	vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Comment" })
	vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
	vim.keymap.set({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })
	vim.keymap.set("n", "<leader>vr", function()
		-- Stateful modules reuse their tables so active jobs and floats survive.
		for name, module in pairs(package.loaded) do
			if name:match("^config%.") and type(module) == "table" then
				local path = vim.fn.stdpath("config") .. "/lua/" .. name:gsub("%.", "/") .. ".lua"
				if vim.fn.filereadable(path) == 1 then
					package.loaded[name] = dofile(path)
				else
					package.loaded[name] = nil
				end
			end
		end
		vim.cmd.source(vim.env.MYVIMRC)
		vim.notify("Neovim configuration reloaded")
	end, { desc = "Reload init.lua and config modules" })

	vim.keymap.set("n", "<C-h>", function()
		M.smart_navigate("wincmd h", "-L")
	end, { desc = "Navigate left" })
	vim.keymap.set("n", "<C-j>", function()
		M.smart_navigate("wincmd j", "-D")
	end, { desc = "Navigate down" })
	vim.keymap.set("n", "<C-k>", function()
		M.smart_navigate("wincmd k", "-U")
	end, { desc = "Navigate up" })
	vim.keymap.set("n", "<C-l>", function()
		M.smart_navigate("wincmd l", "-R")
	end, { desc = "Navigate right" })
	vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
	vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
	vim.keymap.set("n", "<leader>st", "<C-w>T", { desc = "Move split into its own tab" })
	vim.keymap.set("n", "<C-S-Up>", ":resize +2<CR>", { desc = "Increase window height" })
	vim.keymap.set("n", "<C-S-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
	vim.keymap.set("n", "<C-S-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
	vim.keymap.set("n", "<C-S-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })
	vim.keymap.set("n", "<Tab>", "gt", { desc = "Change tab" })
	vim.keymap.set("n", "<S-Tab>", "gT", { desc = "Change tab backwards" })
	vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" })
	vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" })
	vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
	vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
	vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
	vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })
	vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })
	vim.keymap.set("n", "<leader>pa", function()
		local path = vim.fn.expand("%:p")
		vim.fn.setreg("+", path)
		print("file:", path)
	end, { desc = "Copy full file path" })
	vim.keymap.set("n", "<leader>pf", function()
		local name = vim.fn.expand("%:t")
		if name == nil or name == "" then
			return
		end
		vim.fn.setreg("+", name)
		print("copied:", name)
	end, { desc = "Copy file basename" })
	vim.keymap.set("n", "<BS>", "<C-^>", { desc = "Switch to alternate buffer" })
	vim.keymap.set("n", "<leader>rr", function()
		if vim.bo.buftype ~= "" then
			return
		end
		local view = vim.fn.winsaveview()
		vim.cmd([[keeppatterns %s/\s\+$//e]])
		vim.fn.winrestview(view)
	end, { desc = "Remove trailing whitespace" })
end

return M
