local M = type(package.loaded["config.options"]) == "table" and package.loaded["config.options"] or {}

function M.setup()
	vim.g.mapleader = " "
	vim.g.maplocalleader = " "
	local opt = vim.opt
	if M.configured then
		opt = vim.opt_global
	end
	M.configured = true

	opt.termguicolors = true
	opt.number = true
	opt.relativenumber = true
	opt.cursorline = true
	opt.wrap = false
	opt.scrolloff = 10
	opt.sidescrolloff = 10

	opt.tabstop = 2
	opt.shiftwidth = 2
	opt.softtabstop = 2
	opt.expandtab = true
	opt.smartindent = true

	opt.ignorecase = true
	opt.smartcase = true

	opt.signcolumn = "yes"
	opt.colorcolumn = "100"
	opt.showmatch = true
	opt.autocomplete = true
	opt.completeopt = "menuone,noinsert,noselect"
	opt.showmode = false
	opt.pumheight = 10
	opt.pumblend = 10
	opt.viewoptions = "folds,curdir"
	opt.synmaxcol = 300
	opt.fillchars = { eob = " " }
	opt.list = true
	opt.listchars = {
		tab = "│ ",
		leadmultispace = "│ ",
		extends = "…",
		precedes = "…",
	}

	opt.writebackup = false
	opt.swapfile = false
	opt.updatetime = 300
	opt.timeoutlen = 500
	opt.ttimeoutlen = 0
	opt.autoread = true

	opt.iskeyword:append("-")
	opt.path:append("**")
	opt.mouse = "a"
	opt.clipboard:append("unnamedplus")
	-- KWin only offers ext-data-control, which wl-clipboard 2.2 lacks; wl-copy then
	-- grabs focus with a popup surface and KDE hands focus to another window (Chrome).
	-- xclip is no better: KWin only syncs with XWayland while an X11 window has focus, so
	-- from a Wayland terminal it sees a separate clipboard. Klipper uses the real one.
	if vim.env.WAYLAND_DISPLAY and vim.env.XDG_CURRENT_DESKTOP == "KDE" and vim.fn.executable("qdbus6") == 1 then
		local function klipper(method, ...)
			local cmd = { "qdbus6", "org.kde.klipper", "/klipper", "org.kde.klipper.klipper." .. method, ... }
			return vim.system(cmd):wait(2000)
		end
		local function copy(lines, regtype)
			klipper("setClipboardContents", table.concat(lines, "\n") .. (regtype == "V" and "\n" or ""))
		end
		local function paste()
			local result = klipper("getClipboardContents")
			if result.code ~= 0 then
				return {}
			end
			-- qdbus6 adds one trailing newline to its output.
			return vim.split((result.stdout:gsub("\n$", "")), "\n")
		end
		vim.g.clipboard = {
			name = "klipper",
			copy = { ["+"] = copy, ["*"] = copy },
			paste = { ["+"] = paste, ["*"] = paste },
			cache_enabled = 0,
		}
	end
	opt.guicursor =
		"n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-CursorIM/lCursor,r-cr:hor20-Cursor/lCursor,o:hor50-Cursor/lCursor,a:blinkwait700-blinkoff400-blinkon250,sm:block-blinkwait175-blinkoff150-blinkon175"

	opt.foldmethod = "expr"
	opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	opt.foldlevel = 99
	opt.splitbelow = true
	opt.splitright = true
	opt.wildmode = "longest:full,full"
	opt.diffopt:append("linematch:60")
	opt.redrawtime = 10000
	opt.maxmempattern = 20000

	local undo_dir = vim.fn.stdpath("data") .. "/undodir"
	vim.fn.mkdir(undo_dir, "p")
	opt.undofile = true
	opt.undodir = undo_dir
end

return M
