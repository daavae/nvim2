local M = {}

local eager = {
	"https://www.github.com/lewis6991/gitsigns.nvim",
	"https://www.github.com/echasnovski/mini.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate" },
	"https://www.github.com/neovim/nvim-lspconfig",
	"https://github.com/creativenull/efmls-configs-nvim",
	"https://github.com/folke/tokyonight.nvim",
	"https://github.com/tpope/vim-obsession",
}

local optional = {
	"https://www.github.com/ibhagwan/fzf-lua",
	"https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/OXY2DEV/markview.nvim",
	"https://github.com/phelipetls/jsonpath.nvim",
	"https://github.com/mason-org/mason.nvim",
	"https://www.github.com/nvim-lua/plenary.nvim",
	"https://github.com/kdheepak/lazygit.nvim",
}

local function declared_plugin_names(extra_optional)
	local names = { ["oil.nvim"] = true }
	for _, specs in ipairs({ eager, optional, extra_optional or {} }) do
		for _, spec in ipairs(specs) do
			local src = type(spec) == "table" and spec.src or spec
			local name = src and src:match("/([^/]+)$")
			if name then
				names[name] = true
			end
		end
	end
	return names
end

local function clean_lockfile(extra_optional)
	local path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok or #lines == 0 then
		return
	end
	local decoded_ok, lock = pcall(vim.json.decode, table.concat(lines, "\n"))
	if not decoded_ok or type(lock.plugins) ~= "table" then
		return
	end
	local declared = declared_plugin_names(extra_optional)
	local changed = false
	for name in pairs(lock.plugins) do
		if not declared[name] then
			lock.plugins[name] = nil
			changed = true
		end
	end
	if changed then
		vim.fn.writefile(vim.split(vim.json.encode(lock, { indent = "  ", sort_keys = true }), "\n"), path)
	end
end

function M.ensure(name)
	local ok, err = pcall(vim.cmd.packadd, name)
	if not ok then
		vim.notify("Failed to load " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
	end
	return ok
end

local function lazy(name, loader)
	return function()
		if not M.ensure(name) then
			return nil
		end
		return loader()
	end
end

local markview_loaded = false
M.get_markview = lazy("markview.nvim", function()
	if not markview_loaded then
		require("markview").setup({})
		markview_loaded = true
	end
	return require("markview")
end)

M.get_jsonpath = lazy("jsonpath.nvim", function()
	return require("jsonpath")
end)

local fzf_loaded = false
M.get_fzf = lazy("fzf-lua", function()
	M.ensure("nvim-web-devicons")
	local fzf = require("fzf-lua")
	if not fzf_loaded then
		fzf.setup({})
		fzf_loaded = true
	end
	return fzf
end)

function M.get_fzf_actions()
	return M.get_fzf() and require("fzf-lua.actions") or nil
end

function M.setup(extra_optional)
	-- Remove stale committed entries before vim.pack synchronizes the lockfile.
	clean_lockfile(extra_optional)
	vim.pack.add(eager)
	vim.pack.add(optional, { load = function() end })
	if extra_optional and #extra_optional > 0 then
		vim.pack.add(extra_optional, { load = function() end })
	end
	clean_lockfile(extra_optional)
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("UserConfigPluginLock", { clear = true }),
		callback = function()
			clean_lockfile(extra_optional)
		end,
	})

	for _, name in ipairs({
		"nvim-treesitter",
		"gitsigns.nvim",
		"mini.nvim",
		"nvim-treesitter-context",
		"vim-obsession",
		"nvim-lspconfig",
		"efmls-configs-nvim",
	}) do
		M.ensure(name)
	end

	if not package.loaded.mason then
		vim.api.nvim_create_user_command("Mason", function(opts)
			pcall(vim.api.nvim_del_user_command, "Mason")
			if M.ensure("mason.nvim") then
				require("mason").setup({})
				vim.cmd("Mason" .. (opts.args ~= "" and (" " .. opts.args) or ""))
			end
		end, { nargs = "*", force = true })
	end

	if not package.loaded.markview then
		vim.api.nvim_create_user_command("Markview", function(opts)
			pcall(vim.api.nvim_del_user_command, "Markview")
			if M.get_markview() then
				vim.cmd("Markview" .. (opts.args ~= "" and (" " .. opts.args) or ""))
			end
		end, { nargs = "*", force = true })
	end

	return M
end

return M
