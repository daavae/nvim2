local M = type(package.loaded["config.plugins"]) == "table" and package.loaded["config.plugins"] or {}

local eager = {
	"https://www.github.com/lewis6991/gitsigns.nvim",
	"https://www.github.com/echasnovski/mini.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main", build = ":TSUpdate" },
	"https://www.github.com/neovim/nvim-lspconfig",
	"https://github.com/creativenull/efmls-configs-nvim",
	"https://github.com/bluz71/vim-moonfly-colors",
	"https://github.com/tpope/vim-obsession",
}

local optional = {
	"https://www.github.com/ibhagwan/fzf-lua",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/mikavilpas/yazi.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/OXY2DEV/markview.nvim",
	"https://github.com/mason-org/mason.nvim",
}

local function declared_plugin_names(extra_optional)
	local names = {}
	for _, specs in ipairs({ eager, optional, extra_optional or {} }) do
		for _, spec in ipairs(specs) do
			local src = type(spec) == "table" and spec.src or spec
			local name = src and src:match("/([^/]+)$")
			if name then
				name = name:gsub("%.git$", "")
				names[name] = true
			end
		end
	end
	return names
end

local function remove_retired_plugins(extra_optional)
	local ok, installed = pcall(vim.pack.get, nil, { info = false })
	if not ok then
		vim.notify("Failed to inspect installed plugins: " .. tostring(installed), vim.log.levels.WARN)
		return
	end
	local declared = declared_plugin_names(extra_optional)
	local retired = {}
	for _, plugin in ipairs(installed) do
		if not declared[plugin.spec.name] then
			retired[#retired + 1] = plugin.spec.name
		end
	end
	if #retired > 0 then
		local deleted, err = pcall(vim.pack.del, retired)
		if not deleted then
			vim.notify("Failed to remove retired plugins: " .. tostring(err), vim.log.levels.WARN)
		end
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

M.get_markview = lazy("markview.nvim", function()
	if not M.markview_loaded then
		require("markview").setup({
			markdown_inline = {
				checkboxes = {
					checked = { text = "☑" },
					unchecked = { text = "☐" },
				},
			},
		})
		M.markview_loaded = true
	end
	return require("markview")
end)

M.get_fzf = lazy("fzf-lua", function()
	M.ensure("nvim-web-devicons")
	local fzf = require("fzf-lua")
	if not M.fzf_loaded then
		-- fd/rg already respect .gitignore; these only matter for the find/grep fallback.
		local skip = { ".git", "node_modules", ".venv" }
		local grep_defaults = require("fzf-lua.defaults").defaults.grep.grep_opts
		fzf.setup({
			files = {
				find_opts = [[-type d \( -name ]]
					.. table.concat(skip, [[ -o -name ]])
					.. [[ \) -prune -o -type f -print]],
			},
			grep = {
				grep_opts = "--exclude-dir=" .. table.concat(skip, " --exclude-dir=") .. " " .. grep_defaults,
			},
		})
		M.fzf_loaded = true
	end
	return fzf
end)

function M.get_fzf_actions()
	return M.get_fzf() and require("fzf-lua.actions") or nil
end

function M.setup(extra_optional)
	-- vim.pack caches its lock data for the lifetime of the process. Re-running
	-- synchronization after another Neovim instance changed the lockfile can make
	-- existing plugin directories look like failed clones, so only sync at startup.
	if vim.v.vim_did_enter == 0 then
		vim.pack.add(eager)
		vim.pack.add(optional, { load = function() end })
		if extra_optional and #extra_optional > 0 then
			vim.pack.add(extra_optional, { load = function() end })
		end
		remove_retired_plugins(extra_optional)
	end

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
