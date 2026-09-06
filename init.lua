-- Byte-compile and cache Lua modules to speed up startup (Nvim 0.9+).
if vim.loader and vim.loader.enable then
	pcall(vim.loader.enable)
end

vim.opt.termguicolors = true

-- Add a directory to PATH only if it exists and is not already present.
-- This keeps startup idempotent when the config is re-sourced.
local function prepend_to_path(path)
	if not path or path == "" or vim.fn.isdirectory(path) ~= 1 then
		return
	end

	local sep = ":"
	local current_path = vim.env.PATH or ""
	for entry in string.gmatch(current_path, "([^" .. sep .. "]+)") do
		if entry == path then
			return
		end
	end

	if current_path == "" then
		vim.env.PATH = path
	else
		vim.env.PATH = path .. sep .. current_path
	end
end

-- Some tools/plugins in this config expect `node` to be available. When Neovim
-- is launched outside a login shell, PATH can be incomplete, so probe common
-- locations and prepend the first working Node binary we find.
local function ensure_node_in_path()
	if vim.fn.executable("node") == 1 then
		return
	end

	local home = vim.env.HOME or ""
	local nvm_bins = vim.fn.glob(home .. "/.nvm/versions/node/*/bin", false, true)
	table.sort(nvm_bins)

	for i = #nvm_bins, 1, -1 do
		prepend_to_path(nvm_bins[i])
		if vim.fn.executable("node") == 1 then
			return
		end
	end

	local sysname = vim.uv.os_uname().sysname
	if sysname == "Darwin" then
		prepend_to_path("/opt/homebrew/bin")
	elseif sysname == "Linux" then
		prepend_to_path("/home/linuxbrew/.linuxbrew/bin")
	end
	prepend_to_path("/usr/local/bin")
end

-- Mason-installed language servers live here on both macOS and Linux. The UI
-- plugin can stay lazy while its executables remain available to vim.lsp.
prepend_to_path(vim.fn.stdpath("data") .. "/mason/bin")
ensure_node_in_path()

-- =================================================================================
-- OPTIONS
-- =================================================================================
vim.opt.number = true -- line number
vim.opt.relativenumber = true -- relative line numbers
vim.opt.cursorline = true -- highlight current line
vim.opt.wrap = false -- do not wrap lines by default
vim.opt.scrolloff = 10 -- keep 10 lines above/below cursor
vim.opt.sidescrolloff = 10 -- keep 10 columns to left/right of cursor

vim.opt.tabstop = 2 -- tabwidth
vim.opt.shiftwidth = 2 -- indent width
vim.opt.softtabstop = 2 -- soft tab stop not tabs on tab/backspace
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.smartindent = true -- smart auto-indent
vim.opt.autoindent = true -- copy indent from current line

vim.opt.ignorecase = true -- case insensitive search
vim.opt.smartcase = true -- case sensitive if uppercase in string
vim.opt.hlsearch = true -- highlight search matches
vim.opt.incsearch = true -- show matches as you type

vim.opt.signcolumn = "yes" -- always show a sign column
vim.opt.colorcolumn = "100" -- show a column at 100 position chars
vim.opt.showmatch = true -- highlights matching brackets
vim.opt.cmdheight = 1 -- single line command line
vim.opt.completeopt = "menuone,noinsert,noselect" -- completion options
vim.opt.showmode = false -- do not show the mode, instead have it in statusline
vim.opt.pumheight = 10 -- popup menu height
vim.opt.pumblend = 10 -- popup menu transparency
vim.opt.winblend = 0 -- floating window transparency
vim.opt.viewoptions = "folds,curdir" -- persist folds; cursor position is restored separately
vim.opt.conceallevel = 0 -- do not hide markup
vim.opt.concealcursor = "" -- do not hide cursorline in markup
vim.opt.lazyredraw = true -- do not redraw during macros
vim.opt.synmaxcol = 300 -- syntax highlighting limit
vim.opt.fillchars = { eob = " " } -- hide "~" on empty lines

vim.opt.backup = false -- do not create a backup file
vim.opt.writebackup = false -- do not write to a backup file
vim.opt.swapfile = false -- do not create a swapfile
vim.opt.updatetime = 300 -- faster completion
vim.opt.timeoutlen = 500 -- timeout duration
vim.opt.ttimeoutlen = 0 -- key code timeout
vim.opt.autoread = true -- auto-reload changes if outside of neovim
vim.opt.autowrite = false -- do not auto-save

vim.opt.hidden = true -- allow hidden buffers
vim.opt.errorbells = false -- no error sounds
vim.opt.backspace = "indent,eol,start" -- better backspace behaviour
vim.opt.autochdir = false -- do not autochange directories
vim.opt.iskeyword:append("-") -- include - in words
vim.opt.path:append("**") -- include subdirs in search
vim.opt.selection = "inclusive" -- include last char in selection
vim.opt.mouse = "a" -- enable mouse support
vim.opt.clipboard:append("unnamedplus") -- use system clipboard
vim.opt.modifiable = true -- allow buffer modifications
vim.opt.encoding = "utf-8" -- set encoding

vim.opt.guicursor =
	"n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-CursorIM/lCursor,r-cr:hor20-Cursor/lCursor,o:hor50-Cursor/lCursor,a:blinkwait700-blinkoff400-blinkon250,sm:block-blinkwait175-blinkoff150-blinkon175" -- cursor blinking and settings

-- Folding: requires treesitter available at runtime; safe fallback if not
vim.opt.foldmethod = "expr" -- use expression for folding
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- use treesitter for folding
vim.opt.foldlevel = 99 -- start with all folds open

vim.opt.splitbelow = true -- horizontal splits go below
vim.opt.splitright = true -- vertical splits go right
vim.opt.equalalways = true -- keep splits balanced when the editor is resized
vim.opt.eadirection = "both" -- rebalance both width and height

vim.opt.wildmenu = true -- tab completion
vim.opt.wildmode = "longest:full,full" -- complete longest common match, full completion list, cycle through with Tab
vim.opt.diffopt:append("linematch:60") -- improve diff display
vim.opt.redrawtime = 10000 -- increase neovim redraw tolerance
vim.opt.maxmempattern = 20000 -- increase max memory

vim.g.mapleader = " " -- space for leader
vim.g.maplocalleader = " " -- space for localleader

require("config.format").setup()
require("config.statusline").setup()

-- ============================================================================
-- KEYBINDS
-- ============================================================================
-- better movement in wrapped text
vim.keymap.set("n", "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
vim.keymap.set("n", "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

-- jk to normal mode
vim.keymap.set("i", "jk", "<Esc>", { desc = "jk binded to be esc key to go into normal mode" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result (centered)" })
vim.keymap.set("n", "<C-d>", "<C-d>", { desc = "Half page down" })
vim.keymap.set("n", "<C-u>", "<C-u>", { desc = "Half page up" })

local function fold_aware_paragraph(key, forward)
	return function()
		vim.cmd.normal({ key, bang = true })

		local line = vim.fn.line(".")
		local fold_start = vim.fn.foldclosed(line)
		if fold_start == -1 then
			return
		end

		local target
		if forward then
			target = math.min(vim.fn.foldclosedend(line) + 1, vim.api.nvim_buf_line_count(0))
		else
			target = math.max(fold_start - 1, 1)
		end

		vim.api.nvim_win_set_cursor(0, { target, 0 })
	end
end

local function jump_closed_fold(forward)
	return function()
		local line = vim.fn.line(".")
		local last = vim.api.nvim_buf_line_count(0)
		local step = forward and 1 or -1
		local target = line + step

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

vim.keymap.set("n", "}", fold_aware_paragraph("}", true), { desc = "Next paragraph (skip folds)" })
vim.keymap.set("n", "{", fold_aware_paragraph("{", false), { desc = "Previous paragraph (skip folds)" })
vim.keymap.set("n", "]z", jump_closed_fold(true), { desc = "Next closed fold" })
vim.keymap.set("n", "[z", jump_closed_fold(false), { desc = "Previous closed fold" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlighing with <Esc>" })
vim.keymap.set("n", "<leader>/", "gcc", { desc = "Comment" })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
vim.keymap.set({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })
vim.keymap.set("n", "<leader>mv", function()
	if not require("config.plugins").get_markview() then
		return
	end
	local buf = vim.api.nvim_get_current_buf()
	local state = require("markview.state")
	local actions = require("markview.actions")
	if state.buf_attached(buf) then
		actions.toggle(buf)
	else
		actions.attach(buf)
	end
end, { desc = "Toggle markdown view" })
vim.keymap.set("n", "<leader>vr", function()
	for name in pairs(package.loaded) do
		if name:match("^config%.") then
			package.loaded[name] = nil
		end
	end
	vim.cmd.source(vim.env.MYVIMRC)
	vim.notify("Neovim configuration reloaded")
end, { desc = "Reload init.lua and config modules" })

local function tabpage_label(tabpage, index)
	local ok, name = pcall(vim.api.nvim_tabpage_get_var, tabpage, "tab_name")
	if ok and type(name) == "string" and name ~= "" then
		return name
	end

	local win = vim.api.nvim_tabpage_get_win(tabpage)
	local buf = vim.api.nvim_win_get_buf(win)
	local bufname = vim.api.nvim_buf_get_name(buf)
	if bufname ~= "" then
		return vim.fn.fnamemodify(bufname, ":t")
	end

	return "Tab " .. tostring(index)
end

function _G.CUSTOM_TABLINE()
	local tabs = vim.api.nvim_list_tabpages()
	local current = vim.api.nvim_get_current_tabpage()
	local parts = {}

	for i, tabpage in ipairs(tabs) do
		local hl = tabpage == current and "%#TabLineSel#" or "%#TabLine#"
		local label = tabpage_label(tabpage, i):gsub("%%", "%%%%")
		table.insert(parts, hl .. "%" .. i .. "T" .. " " .. i .. ":" .. label .. " ")
	end

	table.insert(parts, "%#TabLineFill#%T")
	return table.concat(parts, "")
end

vim.o.showtabline = 2
vim.o.tabline = "%!v:lua.CUSTOM_TABLINE()"

vim.api.nvim_create_user_command("TabRename", function(opts)
	vim.api.nvim_tabpage_set_var(0, "tab_name", opts.args)
	vim.cmd("redrawtabline")
end, { nargs = 1 })

vim.api.nvim_create_user_command("TabRenameClear", function()
	pcall(vim.api.nvim_tabpage_del_var, 0, "tab_name")
	vim.cmd("redrawtabline")
end, { nargs = 0 })

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

local function smart_navigate(wincmd, tmux_flag)
	local before = vim.api.nvim_get_current_win()
	vim.cmd(wincmd)
	if vim.api.nvim_get_current_win() ~= before then
		return
	end
	if vim.env.TMUX == nil or vim.env.TMUX == "" then
		return
	end
	vim.system({ "tmux", "select-pane", "-Z", tmux_flag })
end

vim.keymap.set("n", "<C-h>", function()
	smart_navigate("wincmd h", "-L")
end, { desc = "Navigate left" })
vim.keymap.set("n", "<C-j>", function()
	smart_navigate("wincmd j", "-D")
end, { desc = "Navigate down" })
vim.keymap.set("n", "<C-k>", function()
	smart_navigate("wincmd k", "-U")
end, { desc = "Navigate up" })
vim.keymap.set("n", "<C-l>", function()
	smart_navigate("wincmd l", "-R")
end, { desc = "Navigate right" })

vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })
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

vim.keymap.set("n", "<leader>pa", function() -- show file path
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	print("file:", path)
end, { desc = "Copy full file path" })
vim.keymap.set("n", "<BS>", "<C-^>", { desc = "Switch to alternate buffer" })

vim.keymap.set("n", "<leader>rr", function()
	if vim.bo.buftype ~= "" then
		return
	end
	local view = vim.fn.winsaveview()
	vim.cmd([[%s/\s\+$//e]])
	vim.fn.winrestview(view)
end, { desc = "Remove trailing whitespace" })

vim.keymap.set("n", "<leader>td", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
local function show_signature_help()
	local bufnr = vim.api.nvim_get_current_buf()
	local winid = vim.b[bufnr].signature_help_winid
	if winid and vim.api.nvim_win_is_valid(winid) then
		pcall(vim.api.nvim_win_close, winid, true)
		vim.b[bufnr].signature_help_winid = nil
		return
	end

	vim.lsp.buf.signature_help()
end
vim.keymap.set("n", "<leader>ts", show_signature_help, { desc = "Signature help" })

-- ============================================================================
-- AUTOCMDS
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Create a directory for persistent undo files
local undo_dir = vim.fn.stdpath("data") .. "/undodir"
if not vim.fn.isdirectory(undo_dir) then
	vim.fn.mkdir(undo_dir, "p")
end

-- Enable persistent undo
vim.opt.undofile = true
vim.opt.undodir = undo_dir

local function can_persist_view(buf)
	return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("BufWinLeave", {
	group = augroup,
	desc = "Save folds and cursor view",
	callback = function(args)
		if can_persist_view(args.buf) then
			vim.cmd("silent! mkview")
		end
	end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
	group = augroup,
	desc = "Restore folds and cursor view",
	callback = function(args)
		if can_persist_view(args.buf) then
			vim.cmd("silent! loadview")
		end
	end,
})

vim.api.nvim_create_autocmd("VimResized", {
	group = augroup,
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

require("config.update_remote").setup()

-- return to last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup,
	desc = "Restore last cursor position",
	callback = function()
		if vim.o.diff then -- except in diff mode
			return
		end

		local last_pos = vim.api.nvim_buf_get_mark(0, '"') -- {line, col}
		local last_line = vim.api.nvim_buf_line_count(0)

		local row = last_pos[1]
		if row < 1 or row > last_line then
			return
		end

		pcall(vim.api.nvim_win_set_cursor, 0, last_pos)
	end,
})

require("config.tasks").setup()

if vim.fn.exists(":LspRestart") == 0 then
	vim.api.nvim_create_user_command("LspRestart", function()
		local buf = vim.api.nvim_get_current_buf()
		local clients = {}
		if vim.lsp.get_clients then
			clients = vim.lsp.get_clients({ bufnr = buf })
		elseif vim.lsp.get_active_clients then
			clients = vim.lsp.get_active_clients({ bufnr = buf })
		end

		for _, client in ipairs(clients) do
			if client.stop then
				client:stop(true)
			elseif vim.lsp.stop_client then
				vim.lsp.stop_client(client.id, true)
			end
		end

		vim.defer_fn(function()
			pcall(vim.cmd, "edit")
		end, 100)
	end, { nargs = 0 })
end

-- wrap, linebreak and spellcheck on markdown and text files
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.spell = true
	end,
})

require("config.terminal").setup(smart_navigate)
-- ============================================================================
-- PLUGINS (vim.pack)
-- ============================================================================

local local_ok, local_config = pcall(require, "config.local")
local plugins = require("config.plugins").setup(local_ok and local_config.plugins or nil)
local get_jsonpath = plugins.get_jsonpath
local get_fzf_lua = plugins.get_fzf
local get_fzf_actions = plugins.get_fzf_actions

if local_ok and type(local_config.setup) == "function" then
	local_config.setup({ ensure = plugins.ensure, get_fzf = plugins.get_fzf })
end

require("config.sessions").setup()
require("config.oil").setup(plugins)
vim.cmd.colorscheme("tokyonight-moon")
local function apply_ui_highlights()
	vim.api.nvim_set_hl(0, "Cursor", { fg = "#1a1b26", bg = "#7dcfff" })
	vim.api.nvim_set_hl(0, "CursorIM", { fg = "#1a1b26", bg = "#9ece6a" })
	vim.api.nvim_set_hl(0, "lCursor", { fg = "#1a1b26", bg = "#7dcfff" })
	vim.api.nvim_set_hl(0, "MatchParen", { fg = "#bb9af7", bg = "NONE", bold = true, underline = true })
	vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
		fg = "#ff9e64",
		bg = "NONE",
		bold = true,
		undercurl = true,
		sp = "#ff9e64",
	})

	-- Statusline: one distinct colored block per section, joined by powerline
	-- separators. Separator groups use fg = left block's bg, bg = right block's bg.
	local c_mode = "#82aaff" -- blue
	local c_file = "#3b4261" -- dark blue-grey
	local c_ft = "#c3e88d" -- green
	local c_pos = "#86e1fc" -- cyan
	local c_base = "#1e2030" -- statusline fill
	local c_dark = "#1b1d2b" -- text on bright blocks
	local c_light = "#c8d3f5" -- text on dark blocks
	local c_git = "#ffc777" -- yellow git text (inside file block)

	vim.api.nvim_set_hl(0, "StatusLine", { fg = c_light, bg = c_base })
	vim.api.nvim_set_hl(0, "StMode", { fg = c_dark, bg = c_mode, bold = true })
	vim.api.nvim_set_hl(0, "StModeSep", { fg = c_mode, bg = c_file })
	vim.api.nvim_set_hl(0, "StFile", { fg = c_light, bg = c_file })
	vim.api.nvim_set_hl(0, "StGit", { fg = c_git, bg = c_file, bold = true })
	vim.api.nvim_set_hl(0, "StFileSep", { fg = c_file, bg = c_ft })
	vim.api.nvim_set_hl(0, "StFileType", { fg = c_dark, bg = c_ft, bold = true })
	vim.api.nvim_set_hl(0, "StFileTypeSep", { fg = c_ft, bg = c_base })
	vim.api.nvim_set_hl(0, "StInfo", { fg = c_light, bg = c_base })
	vim.api.nvim_set_hl(0, "StPosSep", { fg = c_pos, bg = c_base })
	vim.api.nvim_set_hl(0, "StPos", { fg = c_dark, bg = c_pos, bold = true })
	-- Inactive window: filename gets a muted highlighted block.
	vim.api.nvim_set_hl(0, "StFileNC", { fg = c_light, bg = c_file, bold = true })
end
local function apply_todo_highlight()
	vim.api.nvim_set_hl(0, "Todo", { fg = "#1a1b26", bg = "#e0af68", bold = true })
end

apply_ui_highlights()
apply_todo_highlight()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup,
	callback = function()
		apply_ui_highlights()
		apply_todo_highlight()
	end,
})

local todo_pattern = [[\v<(TODO|FIXME|HACK|NOTE|BUG|XXX|OPTIMIZE|PERF)>\s*:?]]
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
	group = augroup,
	callback = function(args)
		if vim.bo[args.buf].buftype ~= "" then
			return
		end
		if vim.w.__todo_match_id ~= nil then
			return
		end
		vim.w.__todo_match_id = vim.fn.matchadd("Todo", todo_pattern, 100)
	end,
})
vim.keymap.set("i", "<C-Space>", function()
	vim.lsp.completion.get()
end, { desc = "Trigger completion" })
vim.keymap.set("i", "<CR>", function()
	if vim.fn.pumvisible() ~= 1 then
		return "<CR>"
	end
	return vim.fn.complete_info({ "selected" }).selected == -1 and "<C-n><C-y>" or "<C-y>"
end, { expr = true, desc = "Accept completion or insert newline" })

-- ============================================================================
-- PLUGIN CONFIGS
-- ============================================================================

require("config.treesitter").setup()

require("mini.clue").setup({
	window = {
		delay = 0,
		config = {
			width = "auto",
			border = "rounded",
			row = "auto",
			col = "auto",
		},
	},
	triggers = {
		{ mode = { "n", "x" }, keys = "<Leader>" },
		{ mode = { "n", "x" }, keys = "g" },
		{ mode = "n", keys = "z" },
		{ mode = "n", keys = "[" },
		{ mode = "n", keys = "]" },
		-- Marks
		{ mode = { "n", "x" }, keys = "'" },
		{ mode = { "n", "x" }, keys = "`" },
		-- Registers
		{ mode = { "n", "x" }, keys = '"' },
		{ mode = { "i", "c" }, keys = "<C-r>" },
	},
	clues = {
		require("mini.clue").gen_clues.builtin_completion(),
		require("mini.clue").gen_clues.g(),
		require("mini.clue").gen_clues.marks(),
		require("mini.clue").gen_clues.registers(),
		require("mini.clue").gen_clues.windows(),
		require("mini.clue").gen_clues.z(),
	},
})

vim.keymap.set("n", "<leader>fg", function()
	local fzf = get_fzf_lua()
	if fzf then
		fzf.live_grep()
	end
end, { desc = "FZF Live Grep" })
vim.keymap.set("n", "<leader>fb", function()
	local fzf = get_fzf_lua()
	if fzf then
		fzf.buffers()
	end
end, { desc = "FZF Buffers" })
vim.keymap.set("n", "<leader>fh", function()
	local fzf = get_fzf_lua()
	if fzf then
		fzf.help_tags()
	end
end, { desc = "FZF Help Tags" })
vim.keymap.set("n", "<leader>fk", function()
	local fzf = get_fzf_lua()
	if fzf then
		fzf.keymaps()
	end
end, { desc = "FZF Keymaps" })
vim.keymap.set("n", "<leader>fm", function()
	local fzf = get_fzf_lua()
	if fzf then
		fzf.marks()
	end
end, { desc = "FZF Marks" })
-- Default <CR> for file pickers: open the first (or only) selection in the
-- current window; open any additional marked selections in new tabs.
local function fzf_smart_open(selected, opts)
	local actions = get_fzf_actions()
	if not actions then
		return
	end
	if not selected or #selected == 0 then
		return
	end
	actions.file_edit({ selected[1] }, opts)
	if #selected > 1 then
		actions.file_tabedit(vim.list_slice(selected, 2), opts)
	end
end

local function fzf_visit_paths(cwd)
	local visits = require("mini.visits")
	local fzf = get_fzf_lua()
	local actions = get_fzf_actions()
	if not (fzf and actions) then
		return
	end
	local paths = visits.list_paths(cwd)
	if vim.tbl_isempty(paths) then
		vim.notify("No visited files yet", vim.log.levels.INFO)
		return
	end

	fzf.fzf_exec(paths, {
		prompt = cwd == "" and "Visits (all)> " or "Visits (cwd)> ",
		cwd = cwd == "" and vim.uv.cwd() or cwd,
		previewer = "builtin",
		_type = "file", -- run entries through make_entry.file for icon/theme colors
		file_icons = true,
		color_icons = true,
		path_shorten = true,
		strip_cwd_prefix = cwd ~= "",
		fzf_opts = { ["--multi"] = true }, -- <Tab> marks files; <CR> opens all marked
		actions = {
			-- <CR>: first/only file in current window, extra marked files in tabs
			["default"] = fzf_smart_open,
			["ctrl-s"] = actions.file_split,
			["ctrl-v"] = actions.file_vsplit,
			["ctrl-t"] = actions.file_tabedit,
		},
	})
end

vim.keymap.set("n", "<leader>ff", function()
	local fzf = get_fzf_lua()
	local actions = get_fzf_actions()
	if not (fzf and actions) then
		return
	end
	fzf.files({
		fzf_opts = { ["--multi"] = true }, -- <Tab> marks files
		actions = {
			-- <CR>: first/only file in current window, extra marked files in tabs
			["default"] = fzf_smart_open,
			["ctrl-t"] = actions.file_tabedit, -- all selected in tabs
		},
	})
end, { desc = "FZF Files" })
vim.keymap.set("n", "<leader>fv", function()
	fzf_visit_paths("")
end, { desc = "FZF Visited Files (all)" })
vim.keymap.set("n", "<leader>fx", function()
	local fzf = get_fzf_lua()
	if fzf then
		fzf.diagnostics_document()
	end
end, { desc = "FZF Diagnostics Document" })
vim.keymap.set("n", "<leader>fX", function()
	local fzf = get_fzf_lua()
	if fzf then
		fzf.diagnostics_workspace()
	end
end, { desc = "FZF Diagnostics Workspace" })

vim.keymap.set("n", "<leader>pf", function()
	local name = vim.fn.expand("%:t")
	if name == nil or name == "" then
		return
	end
	vim.fn.setreg("+", name)
	print("copied:", name)
end, { desc = "Copy file basename" })

vim.keymap.set("n", "<leader>jp", function()
	local jp = get_jsonpath()
	if jp then
		print(jp.get())
	end
end, { desc = "Show JSON path" })
vim.keymap.set("n", "<leader>jy", function()
	local jp = get_jsonpath()
	if jp then
		local path = jp.get()
		vim.fn.setreg("+", path)
		print("copied:", path)
	end
end, { desc = "Yank JSON path to clipboard" })

function _G.JSON_WINBAR()
	if vim.bo.filetype ~= "json" then
		return ""
	end
	local jp = get_jsonpath()
	if not jp then
		return ""
	end
	local p = jp.get()
	return (p and p ~= "") and (" " .. p) or ""
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
	group = augroup,
	pattern = "json",
	callback = function()
		vim.wo.winbar = "%{%v:lua.JSON_WINBAR()%}"
	end,
})

require("mini.ai").setup({})
require("mini.comment").setup({})
require("mini.surround").setup({
	mappings = {
		add = "gsa",
		delete = "gsd",
		find = "gsf",
		find_left = "gsF",
		highlight = "gsh",
		replace = "gsr",
		update_n_lines = "gsn",
		suffix_last = "l",
		suffix_next = "n",
	},
})
require("mini.visits").setup({})
require("mini.notify").setup({})

require("gitsigns").setup({
	signs = {
		add = { text = "\u{2590}" }, -- ▏
		change = { text = "\u{2590}" }, -- ▐
		delete = { text = "\u{2590}" }, -- ◦
		topdelete = { text = "\u{25e6}" }, -- ◦
		changedelete = { text = "\u{25cf}" }, -- ●
		untracked = { text = "\u{25cb}" }, -- ○
	},
	signcolumn = true,
	current_line_blame = false,
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

vim.keymap.set("n", "<leader>gg", function()
	if ensure_packadd("plenary.nvim") and ensure_packadd("lazygit.nvim") then
		vim.cmd("LazyGit")
	end
end, { desc = "Open LazyGit" })

-- ============================================================================
-- LSP, Linting, Formatting & Completion
-- ============================================================================
--
local diagnostic_signs = {
	Error = " ",
	Warn = " ",
	Hint = "",
	Info = "",
}

vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
		header = "",
		prefix = "",
		focusable = false,
		style = "minimal",
	},
})
require("config.lsp_ui").setup()

do
	local yellow = "#e0af68"
	vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = yellow })
	vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = yellow, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DiagnosticSignWarn", { fg = yellow })
	vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = yellow })
end

do
	_G.__config_original_open_floating_preview = _G.__config_original_open_floating_preview
		or vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return _G.__config_original_open_floating_preview(contents, syntax, opts, ...)
	end
end

local native_signature_help_handler = function(err, result, ctx, config)
	-- Neovim 0.12 removed `vim.lsp.with`, so merge handler options manually
	-- before delegating to the built-in signature help handler.
	config = vim.tbl_deep_extend("force", {
		border = "rounded",
		focusable = false,
		close_events = { "InsertLeave", "BufHidden", "CursorMoved", "CursorMovedI" },
	}, config or {})

	return vim.lsp.handlers.signature_help(err, result, ctx, config)
end

vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
	-- Explicitly close stale signature windows when a server reports "no
	-- signatures"; otherwise the previous popup can remain visible.
	local bufnr = ctx and ctx.bufnr
	if bufnr and (result == nil or result.signatures == nil or vim.tbl_isempty(result.signatures)) then
		local winid = vim.b[bufnr].signature_help_winid
		if winid and vim.api.nvim_win_is_valid(winid) then
			pcall(vim.api.nvim_win_close, winid, true)
		end
		vim.b[bufnr].signature_help_winid = nil
		return
	end

	local handler_result, winid = native_signature_help_handler(err, result, ctx, config)
	if bufnr then
		if winid and vim.api.nvim_win_is_valid(winid) then
			vim.b[bufnr].signature_help_winid = winid
		else
			vim.b[bufnr].signature_help_winid = nil
		end
	end

	return handler_result, winid
end

-- Prefer "real" language servers over `efm` for jump/navigation requests.
-- `efm` remains useful for formatting/linting, but is not usually the best
-- source of definitions, references, and similar LSP queries.
local function get_preferred_client(bufnr, method)
	local clients = vim.lsp.get_clients({ bufnr = bufnr, method = method })
	if #clients == 0 then
		return nil
	end

	for _, candidate in ipairs(clients) do
		if candidate.name ~= "efm" then
			return candidate
		end
	end

	return clients[1]
end

local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local opts = { noremap = true, silent = true, buffer = bufnr }
	local function with_desc(desc)
		return vim.tbl_extend("force", opts, { desc = desc })
	end

	if not vim.b[bufnr].lsp_buffer_setup_done then
		vim.b[bufnr].lsp_buffer_setup_done = true

		-- Custom definition peek/open flow so navigation can prefer non-efm
		-- clients and share one implementation across several mappings.
		local function peek_definition()
			local definition_client = get_preferred_client(bufnr, "textDocument/definition")
			if not definition_client then
				vim.notify("No definition provider attached", vim.log.levels.INFO)
				return
			end

			local params = vim.lsp.util.make_position_params(0, definition_client.offset_encoding)
			definition_client:request("textDocument/definition", params, function(err, result)
				if err then
					vim.notify(err.message or tostring(err), vim.log.levels.ERROR)
					return
				end
				if result == nil then
					vim.notify("No definition found", vim.log.levels.INFO)
					return
				end
				local location = result
				if type(result) == "table" and (result.uri == nil and result.targetUri == nil) then
					location = result[1]
					if #result > 1 then
						vim.notify(("Multiple definitions (%d), showing first"):format(#result), vim.log.levels.INFO)
					end
				end
				if location == nil then
					vim.notify("No definition found", vim.log.levels.INFO)
					return
				end
				vim.lsp.util.preview_location(location, { border = "rounded" })
			end, bufnr)
		end

		vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, with_desc("Go to definition"))
		vim.keymap.set("n", "<leader>gp", peek_definition, with_desc("Peek definition"))
		vim.keymap.set("n", "<leader>gS", function()
			vim.cmd("vsplit")
			vim.lsp.buf.definition()
		end, with_desc("Definition (vsplit)"))

		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, with_desc("Code action"))
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, with_desc("Rename symbol"))
		vim.keymap.set("n", "<leader>D", function()
			vim.diagnostic.open_float({ scope = "line" })
		end, with_desc("Diagnostics (line)"))
		vim.keymap.set("n", "<leader>d", function()
			vim.diagnostic.open_float({ scope = "cursor" })
		end, with_desc("Diagnostics (cursor)"))
		vim.keymap.set("n", "K", vim.lsp.buf.hover, with_desc("Hover"))
		vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, with_desc("Signature help"))

		vim.keymap.set("n", "<leader>fd", function()
			local fzf = get_fzf_lua()
			if fzf then
				fzf.lsp_definitions({ jump_to_single_result = true })
			end
		end, with_desc("Definitions (picker)"))
		vim.keymap.set("n", "<leader>fr", function()
			local fzf = get_fzf_lua()
			if fzf then
				fzf.lsp_references()
			end
		end, with_desc("References (picker)"))
		vim.keymap.set("n", "<leader>ft", function()
			local fzf = get_fzf_lua()
			if fzf then
				fzf.lsp_typedefs()
			end
		end, with_desc("Type definitions (picker)"))
		vim.keymap.set("n", "<leader>fs", function()
			local fzf = get_fzf_lua()
			if fzf then
				fzf.lsp_document_symbols()
			end
		end, with_desc("Document symbols (picker)"))
		vim.keymap.set("n", "<leader>fw", function()
			local fzf = get_fzf_lua()
			if fzf then
				fzf.lsp_workspace_symbols()
			end
		end, with_desc("Workspace symbols (picker)"))
		vim.keymap.set("n", "<leader>fi", function()
			local fzf = get_fzf_lua()
			if fzf then
				fzf.lsp_implementations()
			end
		end, with_desc("Implementations (picker)"))
	end

	if client:supports_method("textDocument/codeAction", bufnr) and not vim.b[bufnr].lsp_organize_imports_set then
		vim.b[bufnr].lsp_organize_imports_set = true
		vim.keymap.set("n", "<leader>oi", function()
			local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
			params.context = { only = { "source.organizeImports" }, diagnostics = {} }
			client:request("textDocument/codeAction", params, function(err, actions)
				if err then
					vim.notify(err.message or tostring(err), vim.log.levels.ERROR)
					return
				end
				local action = actions and actions[1]
				if not action then
					vim.notify("No organize-imports action available", vim.log.levels.INFO)
					return
				end
				local function finish(resolved)
					resolved = resolved or action
					if resolved.edit then
						vim.lsp.util.apply_workspace_edit(resolved.edit, client.offset_encoding)
					end
					local command = type(resolved.command) == "table" and resolved.command
						or (type(resolved.command) == "string" and resolved or nil)
					local function format_after_command(command_err)
						if command_err then
							vim.notify(command_err.message or tostring(command_err), vim.log.levels.ERROR)
							return
						end
						vim.lsp.buf.format({ bufnr = bufnr })
					end
					if command then
						if client.commands[command.command] or vim.lsp.commands[command.command] then
							client:exec_cmd(command, { bufnr = bufnr })
							format_after_command()
						else
							client:exec_cmd(command, { bufnr = bufnr }, format_after_command)
						end
					else
						format_after_command()
					end
				end
				if not (action.edit and action.command) and client:supports_method("codeAction/resolve") then
					client:request("codeAction/resolve", action, function(resolve_err, resolved)
						if resolve_err then
							finish(action)
						else
							finish(resolved)
						end
					end, bufnr)
				else
					finish(action)
				end
			end, bufnr)
		end, with_desc("Organize imports"))
	end

	if client:supports_method("textDocument/completion", bufnr) then
		vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
	end
end

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
	vim.b[buf].lsp_buffer_setup_done = nil
	vim.b[buf].lsp_organize_imports_set = nil
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
		lsp_on_attach({ buf = buf, data = { client_id = client.id } })
	end
end

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})
vim.lsp.config("pyright", {})
vim.lsp.config("bashls", {
	filetypes = { "sh", "bash", "zsh" },
})
vim.lsp.config("ts_ls", {})
vim.lsp.config("gopls", {})
vim.lsp.config("clangd", {})

do
	local luacheck = require("efmls-configs.linters.luacheck")
	local stylua = require("efmls-configs.formatters.stylua")

	local black = require("efmls-configs.formatters.black")

	local prettier_d = require("efmls-configs.formatters.prettier_d")
	local eslint_d = require("efmls-configs.linters.eslint_d")

	local fixjson = require("efmls-configs.formatters.fixjson")

	local shellcheck = require("efmls-configs.linters.shellcheck")
	local shfmt = require("efmls-configs.formatters.shfmt")

	local cpplint = require("efmls-configs.linters.cpplint")
	local clangfmt = require("efmls-configs.formatters.clang_format")

	local go_revive = require("efmls-configs.linters.go_revive")
	local gofumpt = require("efmls-configs.formatters.gofumpt")

	vim.lsp.config("efm", {
		filetypes = {
			"c",
			"cpp",
			"css",
			"go",
			"html",
			"javascript",
			"javascriptreact",
			"json",
			"jsonc",
			"lua",
			"markdown",
			"python",
			"sh",
			"bash",
			"zsh",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
		},
		init_options = { documentFormatting = true },
		settings = {
			languages = {
				c = { clangfmt, cpplint },
				go = { gofumpt, go_revive },
				cpp = { clangfmt, cpplint },
				css = { prettier_d },
				html = { prettier_d },
				javascript = { eslint_d, prettier_d },
				javascriptreact = { eslint_d, prettier_d },
				json = { eslint_d, fixjson },
				jsonc = { eslint_d, fixjson },
				lua = { luacheck, stylua },
				markdown = { prettier_d },
				python = { black },
				sh = { shellcheck, shfmt },
				bash = { shellcheck, shfmt },
				zsh = { shellcheck, shfmt },
				typescript = { eslint_d, prettier_d },
				typescriptreact = { eslint_d, prettier_d },
				vue = { eslint_d, prettier_d },
				svelte = { eslint_d, prettier_d },
			},
		},
	})
end

vim.lsp.enable({
	"lua_ls",
	"pyright",
	"bashls",
	"ts_ls",
	"gopls",
	"clangd",
	"efm",
})

require("config.health").setup()
