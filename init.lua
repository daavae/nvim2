vim.opt.termguicolors = true
vim.cmd.colorscheme("unokai")

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
vim.opt.conceallevel = 0 -- do not hide markup
vim.opt.concealcursor = "" -- do not hide cursorline in markup
vim.opt.lazyredraw = true -- do not redraw during macros
vim.opt.synmaxcol = 300 -- syntax highlighting limit
vim.opt.fillchars = { eob = " " } -- hide "~" on empty lines

local undodir = vim.fn.expand("~/.vim/undodir")
if
	vim.fn.isdirectory(undodir) == 0 -- create undodir if nonexistent
then
	vim.fn.mkdir(undodir, "p")
end

vim.opt.backup = false -- do not create a backup file
vim.opt.writebackup = false -- do not write to a backup file
vim.opt.swapfile = false -- do not create a swapfile
vim.opt.undofile = true -- do create an undo file
vim.opt.undodir = undodir -- set the undo directory
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

vim.opt.wildmenu = true -- tab completion
vim.opt.wildmode = "longest:full,full" -- complete longest common match, full completion list, cycle through with Tab
vim.opt.diffopt:append("linematch:60") -- improve diff display
vim.opt.redrawtime = 10000 -- increase neovim redraw tolerance
vim.opt.maxmempattern = 20000 -- increase max memory

-- ============================================================================
-- STATUSLINE
-- ============================================================================

-- Git branch function with caching and Nerd Font icon
local cached_branch = ""
local last_check = 0
local function git_branch()
	local now = vim.loop.now()
	if now - last_check > 5000 then -- Check every 5 seconds
		cached_branch = vim.fn.system("git branch --show-current 2>/dev/null | tr -d '\n'")
		last_check = now
	end
	if cached_branch ~= "" then
		return " \u{e725} " .. cached_branch .. " " -- nf-dev-git_branch
	end
	return ""
end

-- File type with Nerd Font icon
local function file_type()
	local ft = vim.bo.filetype
	local icons = {
		lua = "\u{e620} ", -- nf-dev-lua
		python = "\u{e73c} ", -- nf-dev-python
		javascript = "\u{e74e} ", -- nf-dev-javascript
		typescript = "\u{e628} ", -- nf-dev-typescript
		javascriptreact = "\u{e7ba} ",
		typescriptreact = "\u{e7ba} ",
		html = "\u{e736} ", -- nf-dev-html5
		css = "\u{e749} ", -- nf-dev-css3
		scss = "\u{e749} ",
		json = "\u{e60b} ", -- nf-dev-json
		markdown = "\u{e73e} ", -- nf-dev-markdown
		vim = "\u{e62b} ", -- nf-dev-vim
		sh = "\u{f489} ", -- nf-oct-terminal
		bash = "\u{f489} ",
		zsh = "\u{f489} ",
		rust = "\u{e7a8} ", -- nf-dev-rust
		go = "\u{e724} ", -- nf-dev-go
		c = "\u{e61e} ", -- nf-dev-c
		cpp = "\u{e61d} ", -- nf-dev-cplusplus
		java = "\u{e738} ", -- nf-dev-java
		php = "\u{e73d} ", -- nf-dev-php
		ruby = "\u{e739} ", -- nf-dev-ruby
		swift = "\u{e755} ", -- nf-dev-swift
		kotlin = "\u{e634} ",
		dart = "\u{e798} ",
		elixir = "\u{e62d} ",
		haskell = "\u{e777} ",
		sql = "\u{e706} ",
		yaml = "\u{f481} ",
		toml = "\u{e615} ",
		xml = "\u{f05c} ",
		dockerfile = "\u{f308} ", -- nf-linux-docker
		gitcommit = "\u{f418} ", -- nf-oct-git_commit
		gitconfig = "\u{f1d3} ", -- nf-fa-git
		vue = "\u{fd42} ", -- nf-md-vuejs
		svelte = "\u{e697} ",
		astro = "\u{e628} ",
	}

	if ft == "" then
		return " \u{f15b} " -- nf-fa-file_o
	end

	return ((icons[ft] or " \u{f15b} ") .. ft)
end

-- File size with Nerd Font icon
local function file_size()
	local size = vim.fn.getfsize(vim.fn.expand("%"))
	if size < 0 then
		return ""
	end
	local size_str
	if size < 1024 then
		size_str = size .. "B"
	elseif size < 1024 * 1024 then
		size_str = string.format("%.1fK", size / 1024)
	else
		size_str = string.format("%.1fM", size / 1024 / 1024)
	end
	return " \u{f016} " .. size_str .. " " -- nf-fa-file_o
end

-- Mode indicators with Nerd Font icons
local function mode_icon()
	local mode = vim.fn.mode()
	local modes = {
		n = " \u{f121}  NORMAL",
		i = " \u{f11c}  INSERT",
		v = " \u{f0168} VISUAL",
		V = " \u{f0168} V-LINE",
		["\22"] = " \u{f0168} V-BLOCK",
		c = " \u{f120} COMMAND",
		s = " \u{f0c5} SELECT",
		S = " \u{f0c5} S-LINE",
		["\19"] = " \u{f0c5} S-BLOCK",
		R = " \u{f044} REPLACE",
		r = " \u{f044} REPLACE",
		["!"] = " \u{f489} SHELL",
		t = " \u{f120} TERMINAL",
	}
	return modes[mode] or (" \u{f059} " .. mode)
end

_G.mode_icon = mode_icon
_G.git_branch = git_branch
_G.file_type = file_type
_G.file_size = file_size

vim.cmd([[
  highlight StatusLineBold gui=bold cterm=bold
]])

-- Function to change statusline based on window focus
local function setup_dynamic_statusline()
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		callback = function()
			vim.opt_local.statusline = table.concat({
				"  ",
				"%#StatusLineBold#",
				"%{v:lua.mode_icon()}",
				"%#StatusLine#",
				" \u{e0b1} %f %h%m%r", -- nf-pl-left_hard_divider
				"%{v:lua.git_branch()}",
				"\u{e0b1} ", -- nf-pl-left_hard_divider
				"%{v:lua.file_type()}",
				"\u{e0b1} ", -- nf-pl-left_hard_divider
				"%{v:lua.file_size()}",
				"%=", -- Right-align everything after this
				" \u{f017} %l:%c  %P ", -- nf-fa-clock_o for line/col
			})
		end,
	})
	vim.api.nvim_set_hl(0, "StatusLineBold", { bold = true })

	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		callback = function()
			vim.opt_local.statusline = "  %f %h%m%r \u{e0b1} %{v:lua.file_type()} %=  %l:%c   %P "
		end,
	})
end

setup_dynamic_statusline()

-- ============================================================================
-- KEYBINDS
-- ============================================================================
vim.g.mapleader = " " -- space for leader
vim.g.maplocalleader = " " -- space for localleader

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
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlighing with <Esc>" })
vim.keymap.set("n", "<leader>/", "gcc", { desc = "Comment" })

vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
vim.keymap.set({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })

vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

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
	vim.fn.system({ "tmux", "select-pane", tmux_flag })
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

vim.keymap.set("n", "<leader>th", ":split | term<CR>", { desc = "Terminal Horizontal" })
vim.keymap.set("n", "<leader>tv", ":vsplit | term<CR>", { desc = "Terminal Vertical" })

-- ============================================================================
-- AUTOCMDS
-- ============================================================================

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = augroup,
	pattern = {
		"*.lua",
		"*.py",
		"*.go",
		"*.js",
		"*.jsx",
		"*.ts",
		"*.tsx",
		"*.json",
		"*.css",
		"*.scss",
		"*.html",
		"*.sh",
		"*.bash",
		"*.zsh",
		"*.c",
		"*.cpp",
		"*.h",
		"*.hpp",
	},
	callback = function(args)
		-- avoid formatting non-file buffers (helps prevent weird write prompts)
		if vim.bo[args.buf].buftype ~= "" then
			return
		end
		if not vim.bo[args.buf].modifiable then
			return
		end
		if vim.api.nvim_buf_get_name(args.buf) == "" then
			return
		end

		local has_efm = false
		for _, c in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
			if c.name == "efm" then
				has_efm = true
				break
			end
		end
		if not has_efm then
			return
		end

		pcall(vim.lsp.buf.format, {
			bufnr = args.buf,
			timeout_ms = 2000,
			filter = function(c)
				return c.name == "efm"
			end,
		})
	end,
})

local update_remote_jobs = {}

vim.api.nvim_create_autocmd("BufWritePost", {
	group = augroup,
	callback = function(args)
		if vim.g.__skip_update_remote == true then
			return
		end
		if vim.bo[args.buf].buftype ~= "" then
			return
		end
		local bufname = vim.api.nvim_buf_get_name(args.buf)
		if bufname == "" then
			return
		end

		local dir = vim.fs.dirname(bufname)
		if not dir or dir == "" then
			return
		end

		local found = vim.fs.find("update_remote.sh", { upward = true, path = dir })[1]
		if not found or found == "" then
			return
		end

		local root = vim.fs.dirname(found)
		if not root or root == "" then
			return
		end

		local job = update_remote_jobs[root]
		if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
			return
		end

		local start_hrtime = vim.uv.hrtime()
		local jobid = vim.fn.jobstart({ "sh", found }, {
			cwd = root,
			stdout_buffered = true,
			stderr_buffered = true,
			on_stdout = function() end,
			on_stderr = function() end,
			on_exit = function(_, code)
				update_remote_jobs[root] = nil
				local duration_ms = math.floor((vim.uv.hrtime() - start_hrtime) / 1e6)
				vim.schedule(function()
					local name = vim.fn.fnamemodify(root, ":t")
					local level = code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
					local msg = code == 0 and ("update_remote finished (" .. duration_ms .. "ms)") or ("update_remote failed (code " .. code .. ", " .. duration_ms .. "ms)")
					vim.notify(msg, level, { title = name })
				end)
			end,
		})

		if jobid > 0 then
			update_remote_jobs[root] = jobid
		end
	end,
})

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

vim.api.nvim_create_user_command("Run", function()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype == "" and vim.bo[buf].modifiable and vim.api.nvim_buf_get_name(buf) ~= "" and vim.bo[buf].modified then
		vim.g.__skip_update_remote = true
		pcall(function()
			vim.cmd("silent write")
		end)
		vim.g.__skip_update_remote = false
	end

	local start_dir = vim.fn.getcwd()
	local bufname = vim.api.nvim_buf_get_name(buf)
	if bufname ~= "" then
		local d = vim.fs.dirname(bufname)
		if d and d ~= "" then
			start_dir = d
		end
	end

	local run_path = vim.fs.find("run.sh", { upward = true, path = start_dir })[1]
	if not run_path or run_path == "" then
		vim.notify("run.sh not found", vim.log.levels.WARN)
		return
	end

	local root = vim.fs.dirname(run_path)
	if not root or root == "" then
		vim.notify("Invalid run.sh path", vim.log.levels.ERROR)
		return
	end

	vim.cmd("botright split")
	pcall(function()
		vim.cmd("resize 15")
	end)
	vim.cmd("enew")
	vim.fn.jobstart({ "sh", run_path }, { term = true, cwd = root })
	vim.cmd("startinsert")
end, { nargs = 0 })

vim.cmd([[cnoreabbrev <expr> run (getcmdtype() == ':' && getcmdline() ==# 'run') ? 'Run' : 'run']])

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

vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
	callback = function()
		vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = true })
		local function tnav(wincmd, tmux_flag)
			vim.api.nvim_feedkeys(vim.keycode("<C-\\><C-n>"), "n", false)
			vim.schedule(function()
				smart_navigate(wincmd, tmux_flag)
			end)
		end
		vim.keymap.set("t", "<C-h>", function()
			tnav("wincmd h", "-L")
		end, { buffer = true, silent = true })
		vim.keymap.set("t", "<C-j>", function()
			tnav("wincmd j", "-D")
		end, { buffer = true, silent = true })
		vim.keymap.set("t", "<C-k>", function()
			tnav("wincmd k", "-U")
		end, { buffer = true, silent = true })
		vim.keymap.set("t", "<C-l>", function()
			tnav("wincmd l", "-R")
		end, { buffer = true, silent = true })
	end,
})
-- ============================================================================
-- PLUGINS (vim.pack)
-- ============================================================================

vim.pack.add({
	"https://www.github.com/lewis6991/gitsigns.nvim",
	"https://www.github.com/echasnovski/mini.nvim",
	"https://www.github.com/ibhagwan/fzf-lua",
	"https://www.github.com/nvim-tree/nvim-tree.lua",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/folke/sidekick.nvim",
	"https://github.com/phelipetls/jsonpath.nvim",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
	},
	-- Language Server Protocols
	"https://www.github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/creativenull/efmls-configs-nvim",
	"https://www.github.com/L3MON4D3/LuaSnip",
	"https://github.com/folke/tokyonight.nvim",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/kdheepak/lazygit.nvim",
})

local function packadd(name)
	vim.cmd("packadd " .. name)
end

packadd("nvim-treesitter")
packadd("gitsigns.nvim")
packadd("mini.nvim")
packadd("fzf-lua")
packadd("nvim-tree.lua")
packadd("nvim-web-devicons")
packadd("jsonpath.nvim")
-- LSP
packadd("nvim-lspconfig")
packadd("mason.nvim")
packadd("efmls-configs-nvim")
packadd("LuaSnip")
vim.cmd.colorscheme("tokyonight-moon")
vim.api.nvim_set_hl(0, "Cursor", { fg = "#1a1b26", bg = "#ff9e64" })
vim.api.nvim_set_hl(0, "CursorIM", { fg = "#1a1b26", bg = "#9ece6a" })
vim.api.nvim_set_hl(0, "lCursor", { fg = "#1a1b26", bg = "#ff9e64" })
local function apply_todo_highlight()
	vim.api.nvim_set_hl(0, "Todo", { fg = "#1a1b26", bg = "#e0af68", bold = true })
end

apply_todo_highlight()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup,
	callback = function()
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
packadd("cmp-nvim-lsp")
packadd("lazygit.nvim")
packadd("sidekick.nvim")
vim.pack.add({
  "https://github.com/hrsh7th/nvim-cmp",
})
packadd("nvim-cmp")
vim.pack.add({
  "https://code.byted.org/chenjiaqi.cposture/codeverse.vim.git",
})
packadd("codeverse.vim")

require("sidekick").setup({
	nes = { enabled = false },
	cli = {
		picker = "fzf-lua",
		mux = {
			backend = "tmux",
			enabled = true,
			create = "terminal",
		},
		win = {
			keys = {
				nav_left = false,
				nav_down = false,
				nav_up = false,
				nav_right = false,
			},
		},
		tools = {
			coco = {
				cmd = { "coco" },
				title = "Coco AI",
				native_scroll = true,
			},
		},
	},
})

local function sidekick_coco_installed()
	if vim.fn.executable("coco") ~= 1 then
		vim.notify("sidekick: `coco` not found in $PATH", vim.log.levels.ERROR)
		return false
	end
	return true
end

local function sidekick_default_coco(opts)
	if opts == nil then
		return { name = "coco" }
	end
	if type(opts) == "string" then
		return opts
	end
	if type(opts) == "table" then
		local has_name = opts.name ~= nil or (opts.filter ~= nil and opts.filter.name ~= nil)
		if not has_name then
			return vim.tbl_extend("force", {}, opts, { name = "coco" })
		end
	end
	return opts
end

do
	local cli = require("sidekick.cli")
	local orig = {
		select = cli.select,
		toggle = cli.toggle,
		show = cli.show,
		focus = cli.focus,
		hide = cli.hide,
		close = cli.close,
		send = cli.send,
	}

	cli.select = function(opts)
		if opts == nil and not sidekick_coco_installed() then
			return
		end
		return orig.select(sidekick_default_coco(opts))
	end

	cli.toggle = function(opts)
		if opts == nil and not sidekick_coco_installed() then
			return
		end
		return orig.toggle(sidekick_default_coco(opts))
	end

	cli.show = function(opts)
		if opts == nil and not sidekick_coco_installed() then
			return
		end
		return orig.show(sidekick_default_coco(opts))
	end

	cli.focus = function(opts)
		return orig.focus(sidekick_default_coco(opts))
	end

	cli.hide = function(opts)
		return orig.hide(sidekick_default_coco(opts))
	end

	cli.close = function(opts)
		return orig.close(sidekick_default_coco(opts))
	end

	cli.send = function(opts)
		if type(opts) == "string" then
			if not sidekick_coco_installed() then
				return
			end
			return orig.send({ msg = opts, name = "coco" })
		end
		if opts == nil and not sidekick_coco_installed() then
			return
		end
		return orig.send(sidekick_default_coco(opts))
	end
end

vim.keymap.set({ "n", "t", "i", "x" }, "<C-.>", function()
	require("sidekick.cli").focus({ name = "coco" })
end, { desc = "Sidekick: Focus" })
vim.keymap.set({ "n", "t", "i" }, "<M-u>", function()
	require("sidekick.cli").toggle({ name = "coco", focus = true })
end, { desc = "Sidekick: Toggle (Option+U)" })
vim.keymap.set("x", "<M-u>", function()
	require("sidekick.cli").send({ msg = "{this}", name = "coco" })
end, { desc = "Sidekick: Send This (Option+U)" })
vim.keymap.set("n", "<leader>aa", function()
	require("sidekick.cli").toggle({ name = "coco", focus = true })
end, { desc = "Sidekick: Toggle CLI" })
vim.keymap.set("n", "<leader>as", function()
	require("sidekick.cli").select({ name = "coco", focus = true })
end, { desc = "Sidekick: Select CLI" })
vim.keymap.set("n", "<leader>ad", function()
	require("sidekick.cli").hide({ name = "coco" })
end, { desc = "Sidekick: Hide" })
vim.keymap.set("n", "<leader>aD", function()
	require("sidekick.cli").close({ name = "coco" })
end, { desc = "Sidekick: Detach CLI" })
vim.keymap.set({ "n", "x" }, "<leader>ap", function()
	require("sidekick.cli").prompt()
end, { desc = "Sidekick: Prompt" })
vim.keymap.set({ "n", "x" }, "<leader>at", function()
	require("sidekick.cli").send({ msg = "{this}", name = "coco" })
end, { desc = "Sidekick: Send This" })
vim.keymap.set("n", "<leader>af", function()
	require("sidekick.cli").send({ msg = "{file}", name = "coco" })
end, { desc = "Sidekick: Send File" })
vim.keymap.set("x", "<leader>av", function()
	require("sidekick.cli").send({ msg = "{selection}", name = "coco" })
end, { desc = "Sidekick: Send Selection" })
vim.keymap.set("n", "<leader>ac", function()
	require("sidekick.cli").toggle({ name = "coco", focus = true })
end, { desc = "Sidekick: Coco" })

require("trae").setup({})
local cmp = require("cmp")
cmp.setup({
	mapping = {
		["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
		["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
		["<C-e>"] = cmp.mapping.abort(),
		["<C-Space>"] = cmp.mapping.complete(),
		["<CR>"] = function(fallback)
			if cmp.visible() then
				cmp.confirm({ select = true })
			else
				fallback()
			end
		end,
	},
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	sources = cmp.config.sources({
		{ name = "trae", group_index = 1 },
		{ name = "nvim_lsp" },
	}),
	experimental = {
		ghost_text = true,
	},
})

-- ============================================================================
-- PLUGIN CONFIGS
-- ============================================================================

local setup_treesitter = function()
	local treesitter = require("nvim-treesitter")
	treesitter.setup({})
	local ensure_installed = {
		"vim",
		"vimdoc",
		"rust",
		"c",
		"cpp",
		"go",
		"html",
		"css",
		"javascript",
		"json",
		"lua",
		"markdown",
		"python",
		"typescript",
		"vue",
		"svelte",
		"bash",
		"lua",
		"python",
	}

	local config = require("nvim-treesitter.config")

	local already_installed = config.get_installed()
	local parsers_to_install = {}

	for _, parser in ipairs(ensure_installed) do
		if not vim.tbl_contains(already_installed, parser) then
			table.insert(parsers_to_install, parser)
		end
	end

	if #parsers_to_install > 0 then
		treesitter.install(parsers_to_install)
	end

	local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			if vim.list_contains(treesitter.get_installed(), vim.treesitter.language.get_lang(args.match)) then
				vim.treesitter.start(args.buf)
			end
		end,
	})
end

setup_treesitter()

local function nvim_tree_on_attach(bufnr)
	local api = require("nvim-tree.api")
	-- Restore all default nvim-tree keymaps first
	api.config.mappings.default_on_attach(bufnr)
	local function cp(rel)
		local node = api.tree.get_node_under_cursor()
		if not node then
			return
		end
		local path = rel and vim.fn.fnamemodify(node.path, ":.") or node.path
		vim.fn.setreg("+", path)
		print(rel and "rel:" or "abs:", path)
	end
	vim.keymap.set("n", "<CR>", function()
		api.node.open.edit()
	end, { buffer = bufnr, noremap = true, silent = true })
	local nav_opts = { buffer = bufnr, noremap = true, silent = true, nowait = true }
	vim.keymap.set("n", "S", api.tree.search_node, vim.tbl_extend("force", nav_opts, { desc = "Search node" }))
	vim.keymap.set("n", "f", api.live_filter.start, vim.tbl_extend("force", nav_opts, { desc = "Live filter" }))
	vim.keymap.set("n", "F", api.live_filter.clear, vim.tbl_extend("force", nav_opts, { desc = "Clear live filter" }))
	vim.keymap.set("n", "g?", api.tree.toggle_help, vim.tbl_extend("force", nav_opts, { desc = "Help" }))
	vim.keymap.set("n", "gf", api.tree.find_file, vim.tbl_extend("force", nav_opts, { desc = "Find current file" }))
	local function mouse_on_node()
		local pos = vim.fn.getmousepos()
		if pos.line < 1 then
			return false
		end
		pcall(vim.api.nvim_win_set_cursor, 0, { pos.line, math.max(pos.column - 1, 0) })
		local line = vim.api.nvim_buf_get_lines(bufnr, pos.line - 1, pos.line, false)[1] or ""
		local first_byte = line:find("%S")
		if first_byte == nil then
			return false
		end
		local first_col = vim.fn.strdisplaywidth(line:sub(1, first_byte - 1)) + 1
		local last_col = vim.fn.strdisplaywidth(line)
		return pos.column >= first_col and pos.column <= last_col
	end

	vim.keymap.set("n", "<LeftRelease>", function()
		if not mouse_on_node() then
			return
		end
		local node = api.tree.get_node_under_cursor()
		if node and node.nodes ~= nil then
			api.node.open.edit()
		else
			api.node.open.preview()
		end
	end, { buffer = bufnr, noremap = true, silent = true })
	vim.keymap.set("n", "yr", function()
		cp(true)
	end, { buffer = bufnr, noremap = true, silent = true, desc = "Copy relative path" })
	vim.keymap.set("n", "ya", function()
		cp(false)
	end, { buffer = bufnr, noremap = true, silent = true, desc = "Copy absolute path" })
end

require("nvim-tree").setup({
	view = {
		width = 35,
	},
	filters = {
		dotfiles = false,
	},
	git = {
		enable = true,
		ignore = false,
	},
	renderer = {
		group_empty = true,
	},
	update_focused_file = {
		enable = true,
		update_root = false,
	},
	live_filter = {
		always_show_folders = false,
	},
	on_attach = nvim_tree_on_attach,
})
vim.keymap.set("n", "<leader>e", function()
	require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })

vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeSignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { fg = "#2a2a2a", bg = "none" })
vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { bg = "none" })

require("fzf-lua").setup({})
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

vim.keymap.set("n", "<leader>ff", function()
	require("fzf-lua").files()
end, { desc = "FZF Files" })
vim.keymap.set("n", "<leader>fg", function()
	require("fzf-lua").live_grep()
end, { desc = "FZF Live Grep" })
vim.keymap.set("n", "<leader>fb", function()
	require("fzf-lua").buffers()
end, { desc = "FZF Buffers" })
vim.keymap.set("n", "<leader>fh", function()
	require("fzf-lua").help_tags()
end, { desc = "FZF Help Tags" })
vim.keymap.set("n", "<leader>fx", function()
	require("fzf-lua").diagnostics_document()
end, { desc = "FZF Diagnostics Document" })
vim.keymap.set("n", "<leader>fX", function()
	require("fzf-lua").diagnostics_workspace()
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
	local ok, jp = pcall(require, "jsonpath")
	if ok then
		print(jp.get())
	end
end, { desc = "Show JSON path" })
vim.keymap.set("n", "<leader>jy", function()
	local ok, jp = pcall(require, "jsonpath")
	if ok then
		local path = jp.get()
		vim.fn.setreg("+", path)
		print("copied:", path)
	end
end, { desc = "Yank JSON path to clipboard" })

function _G.JSON_WINBAR()
	if vim.bo.filetype ~= "json" then
		return ""
	end
	local ok, jp = pcall(require, "jsonpath")
	if not ok then
		return ""
	end
	local p = jp.get()
	return (p and p ~= "") and (" " .. p) or ""
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
	pattern = "json",
	callback = function()
		vim.wo.winbar = "%{%v:lua.JSON_WINBAR()%}"
	end,
})

require("mini.ai").setup({})
require("mini.comment").setup({})
require("mini.move").setup({})
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
require("mini.cursorword").setup({})
require("mini.indentscope").setup({})
require("mini.pairs").setup({})
require("mini.trailspace").setup({})
require("mini.bufremove").setup({})
require("mini.notify").setup({})
require("mini.icons").setup({})

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

require("mason").setup({})

vim.keymap.set("n", "]h", function()
	require("gitsigns").next_hunk()
end, { desc = "Next git hunk" })
vim.keymap.set("n", "[h", function()
	require("gitsigns").prev_hunk()
end, { desc = "Previous git hunk" })
vim.keymap.set("n", "<leader>hs", function()
	require("gitsigns").stage_hunk()
end, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hr", function()
	require("gitsigns").reset_hunk()
end, { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>hp", function()
	require("gitsigns").preview_hunk()
end, { desc = "Preview hunk" })
vim.keymap.set("n", "<leader>hb", function()
	require("gitsigns").blame_line({ full = true })
end, { desc = "Blame line" })
vim.keymap.set("n", "<leader>hB", function()
	require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle inline blame" })
vim.keymap.set("n", "<leader>hd", function()
	require("gitsigns").diffthis()
end, { desc = "Diff this" })

vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })

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

do
	local yellow = "#e0af68"
	vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = yellow })
	vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = yellow, bg = "NONE" })
	vim.api.nvim_set_hl(0, "DiagnosticSignWarn", { fg = yellow })
	vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = yellow })
end

do
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
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

	local function peek_definition()
		local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
		vim.lsp.buf_request(bufnr, "textDocument/definition", params, function(err, result)
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
		end)
	end

	vim.keymap.set("n", "<leader>gd", function()
		require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
	end, with_desc("Definitions (picker)"))

	vim.keymap.set("n", "<leader>gD", vim.lsp.buf.definition, with_desc("Go to definition"))

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
	vim.keymap.set("n", "<leader>nd", function()
		vim.diagnostic.jump({ count = 1 })
	end, with_desc("Next diagnostic"))

	vim.keymap.set("n", "<leader>pd", function()
		vim.diagnostic.jump({ count = -1 })
	end, with_desc("Prev diagnostic"))

	vim.keymap.set("n", "K", vim.lsp.buf.hover, with_desc("Hover"))

	vim.keymap.set("n", "<leader>fd", function()
		require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
	end, with_desc("Definitions (picker)"))
	vim.keymap.set("n", "<leader>fr", function()
		require("fzf-lua").lsp_references()
	end, with_desc("References (picker)"))
	vim.keymap.set("n", "<leader>ft", function()
		require("fzf-lua").lsp_typedefs()
	end, with_desc("Type definitions (picker)"))
	vim.keymap.set("n", "<leader>fs", function()
		require("fzf-lua").lsp_document_symbols()
	end, with_desc("Document symbols (picker)"))
	vim.keymap.set("n", "<leader>fw", function()
		require("fzf-lua").lsp_workspace_symbols()
	end, with_desc("Workspace symbols (picker)"))
	vim.keymap.set("n", "<leader>fi", function()
		require("fzf-lua").lsp_implementations()
	end, with_desc("Implementations (picker)"))

	if client:supports_method("textDocument/codeAction", bufnr) then
		vim.keymap.set("n", "<leader>oi", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports" }, diagnostics = {} },
				apply = true,
				bufnr = bufnr,
			})
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50)
		end, with_desc("Organize imports"))
	end
end

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

vim.lsp.config["*"] = {
	capabilities = require("cmp_nvim_lsp").default_capabilities(),
}

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})
vim.lsp.config("pyright", {})
vim.lsp.config("bashls", {})
vim.lsp.config("ts_ls", {})
vim.lsp.config("gopls", {})
vim.lsp.config("clangd", {})

do
	local luacheck = require("efmls-configs.linters.luacheck")
	local stylua = require("efmls-configs.formatters.stylua")

	local flake8 = require("efmls-configs.linters.flake8")
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
				python = { flake8, black },
				sh = { shellcheck, shfmt },
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

-- ============================================================================
-- FLOATING TERMINAL
-- ============================================================================

vim.api.nvim_create_autocmd("TermClose", {
	group = augroup,
	pattern = "term://*",
	callback = function(args)
		if vim.v.event.status == 0 then
			local buf = args.buf
			if vim.b[buf].floating_terminal ~= true then
				return
			end
			vim.schedule(function()
				pcall(vim.api.nvim_buf_delete, buf, { force = true })
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	group = augroup,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		pcall(vim.keymap.del, "t", "<Esc>")
		vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = true, noremap = true, silent = true })
	end,
})
vim.api.nvim_create_autocmd("TermEnter", {
	group = augroup,
	pattern = "term://*",
	callback = function()
		pcall(vim.keymap.del, "t", "<Esc>")
		vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = true, noremap = true, silent = true })
	end,
})

local terminal_state = { buf = nil, win = nil, is_open = false }

local function FloatingTerminal()
	if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
		return
	end

	if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
		terminal_state.buf = vim.api.nvim_create_buf(false, true)
		vim.bo[terminal_state.buf].bufhidden = "hide"
		vim.b[terminal_state.buf].floating_terminal = true
	end

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[terminal_state.win].winblend = 0
	vim.wo[terminal_state.win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"
	vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none" })

	local has_terminal = false
	local lines = vim.api.nvim_buf_get_lines(terminal_state.buf, 0, -1, false)
	for _, line in ipairs(lines) do
		if line ~= "" then
			has_terminal = true
			break
		end
	end
	if not has_terminal then
		vim.fn.jobstart({ vim.o.shell }, { term = true })
	end

	terminal_state.is_open = true
	vim.cmd("startinsert")

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = terminal_state.buf,
		callback = function()
			if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
				vim.api.nvim_win_close(terminal_state.win, false)
				terminal_state.is_open = false
			end
		end,
		once = true,
	})
end

vim.keymap.set("n", "<leader>tt", FloatingTerminal, { noremap = true, silent = true, desc = "Toggle floating terminal" })
