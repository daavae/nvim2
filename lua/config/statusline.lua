local M = {}

local branch_cache = {}

local icons = {
	lua = "\u{e620} ",
	python = "\u{e73c} ",
	javascript = "\u{e74e} ",
	typescript = "\u{e628} ",
	javascriptreact = "\u{e7ba} ",
	typescriptreact = "\u{e7ba} ",
	html = "\u{e736} ",
	css = "\u{e749} ",
	scss = "\u{e749} ",
	json = "\u{e60b} ",
	markdown = "\u{e73e} ",
	vim = "\u{e62b} ",
	sh = "\u{f489} ",
	bash = "\u{f489} ",
	zsh = "\u{f489} ",
	rust = "\u{e7a8} ",
	go = "\u{e724} ",
	c = "\u{e61e} ",
	cpp = "\u{e61d} ",
	java = "\u{e738} ",
	php = "\u{e73d} ",
	ruby = "\u{e739} ",
	swift = "\u{e755} ",
	kotlin = "\u{e634} ",
	dart = "\u{e798} ",
	elixir = "\u{e62d} ",
	haskell = "\u{e777} ",
	sql = "\u{e706} ",
	yaml = "\u{f481} ",
	toml = "\u{e615} ",
	xml = "\u{f05c} ",
	dockerfile = "\u{f308} ",
	gitcommit = "\u{f418} ",
	gitconfig = "\u{f1d3} ",
	vue = "\u{fd42} ",
	svelte = "\u{e697} ",
	astro = "\u{e628} ",
}

local function git_branch()
	local head = vim.b.gitsigns_head
	if head and head ~= "" then
		return " \u{e725} " .. head .. " "
	end
	local path = vim.api.nvim_buf_get_name(0)
	-- Skip virtual buffers (oil://, oil-ssh://, term://, ...): their "name"
	-- isn't a real local directory, so spawning git with it as cwd would error.
	if path:find("://", 1, true) then
		return ""
	end
	local cwd = path ~= "" and vim.fs.dirname(path) or vim.uv.cwd()
	if not cwd then
		return ""
	end
	local cache = branch_cache[cwd] or { value = "", last_check = 0, running = false }
	branch_cache[cwd] = cache
	local now = vim.uv.now()
	if now - cache.last_check > 5000 and not cache.running then
		cache.last_check = now
		cache.running = true
		vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true }, function(result)
			cache.running = false
			local output = result.code == 0 and result.stdout or ""
			vim.schedule(function()
				cache.value = output:gsub("%s+$", "")
				vim.cmd("redrawstatus")
			end)
		end)
	end
	return cache.value ~= "" and (" \u{e725} " .. cache.value .. " ") or ""
end

local function file_type()
	local ft = vim.bo.filetype
	return (icons[ft] or " \u{f15b} ") .. (ft ~= "" and ft or "")
end

local function file_size()
	local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
	if size < 0 then
		return ""
	elseif size < 1024 then
		return (" \u{f016} %dB "):format(size)
	elseif size < 1024 * 1024 then
		return (" \u{f016} %.1fK "):format(size / 1024)
	end
	return (" \u{f016} %.1fM "):format(size / 1024 / 1024)
end

local function mode_icon()
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
	return modes[vim.fn.mode()] or (" \u{f059} " .. vim.fn.mode())
end

function M.setup()
	_G.mode_icon = mode_icon
	_G.git_branch = git_branch
	_G.file_type = file_type
	_G.file_size = file_size

	local group = vim.api.nvim_create_augroup("UserConfigStatusline", { clear = true })
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		group = group,
		callback = function()
			vim.opt_local.statusline = table.concat({
				"%#StMode#",
				"%{v:lua.mode_icon()} ",
				"%#StModeSep#\u{e0b0}",
				"%#StFile# %f %h%m%r ",
				"%#StGit#%{v:lua.git_branch()}",
				"%#StFileSep#\u{e0b0}",
				"%#StFileType# %{v:lua.file_type()} ",
				"%#StFileTypeSep#\u{e0b0}",
				"%#StInfo#%{v:lua.file_size()}",
				"%#StInfo#%{v:lua.format_status()}",
				"%#StInfo#%=",
				"%#StPosSep#\u{e0b2}",
				"%#StPos# \u{f017} %l:%c  %P ",
			})
		end,
	})
	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		group = group,
		callback = function()
			vim.opt_local.statusline = table.concat({
				"  ",
				"%#StFileNC# %f %h%m%r ",
				"%#StatusLine# \u{e0b1} %{v:lua.file_type()} %=  %l:%c   %P ",
			})
		end,
	})
end

return M
