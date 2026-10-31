local previous = package.loaded["config.oil"]
local legacy = type(previous) == "table" and previous.state or nil
local M = {}

function M.setup(plugins)
	-- Retire hooks from the old automatic-preview setup when reloading a live editor.
	local migrated = legacy ~= nil
	for _, autocmd in ipairs(vim.api.nvim_get_autocmds({})) do
		if (autocmd.group_name or ""):match("^UserConfigOil") then
			pcall(vim.api.nvim_del_augroup_by_id, autocmd.group)
			migrated = true
		end
	end
	if legacy then
		for _, request in pairs(legacy.preview_requests or {}) do
			request.cancel()
		end
		for _, timer in pairs(legacy.preview_timers or {}) do
			if not timer:is_closing() then
				timer:stop()
				timer:close()
			end
		end
		for buf in pairs(legacy.git_generations or {}) do
			legacy.git_generations[buf] = nil
		end
		if package.loaded.oil and legacy.open_preview then
			package.loaded.oil.open_preview = legacy.open_preview
		end
		legacy = nil
	end
	if migrated then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.w[win].oil_preview then
				vim.api.nvim_win_close(win, true)
			end
		end
		local ns = vim.api.nvim_get_namespaces().OilGitStatus
		if ns then
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
			end
		end
	end
	local ns = vim.api.nvim_create_namespace("OilGitStatus")
	local signs = {
		{ "?", "DiagnosticInfo" },
		{ "~", "DiagnosticWarn" },
		{ "+", "DiagnosticOk" },
		{ "-", "DiagnosticError" },
		{ "!", "DiagnosticError" },
	}
	local function refresh_git(buf)
		local dir = require("oil").get_current_dir(buf)
		local root = dir and vim.fs.root(dir, ".git")
		if not root or vim.fn.executable("git") ~= 1 then
			return
		end
		local prefix = vim.fs.relpath(root, dir)
		prefix = prefix == "." and "" or prefix .. "/"
		local generation = (vim.b[buf].oil_git_generation or 0) + 1
		vim.b[buf].oil_git_generation = generation
		-- Porcelain paths are root-relative; disabling renames keeps every record self-contained.
		vim.system({
			"git",
			"--no-optional-locks",
			"status",
			"--porcelain=v1",
			"-z",
			"--no-renames",
			"--untracked-files=normal",
			"--",
			".",
		}, { cwd = dir, text = true }, function(result)
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].oil_git_generation ~= generation then
					return
				end
				local status = {}
				for _, record in ipairs(vim.split(result.stdout or "", "\0", { plain = true, trimempty = true })) do
					local code, path = record:sub(1, 2), record:sub(4)
					if vim.startswith(path, prefix) then
						local name = path:sub(#prefix + 1):match("^[^/]+")
						local kind = (code:find("U") or code == "AA" or code == "DD") and 5
							or code:find("D") and 4
							or code:find("A") and 3
							or code == "??" and 1
							or 2
						if name then
							status[name] = math.max(status[name] or 0, kind)
						end
					end
				end
				vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
				for row = 1, vim.api.nvim_buf_line_count(buf) do
					local entry = require("oil").get_entry_on_line(buf, row)
					local sign = entry and signs[status[entry.name]]
					if sign then
						vim.api.nvim_buf_set_extmark(
							buf,
							ns,
							row - 1,
							0,
							{ sign_text = sign[1], sign_hl_group = sign[2], priority = 20 }
						)
					end
				end
			end)
		end)
	end
	vim.api.nvim_create_autocmd("User", {
		group = vim.api.nvim_create_augroup("OilGitDecorations", { clear = true }),
		pattern = { "OilEnter", "OilActionsPost" },
		callback = function(args)
			local buf = args.data and args.data.buf or vim.api.nvim_get_current_buf()
			if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "oil" then
				refresh_git(buf)
			end
		end,
	})
	local configured = false
	local function load()
		if configured then
			return require("oil")
		end
		-- Oil chooses its icon provider once, so load colored icons before Oil.
		plugins.ensure("nvim-web-devicons")
		if not plugins.ensure("oil.nvim") then
			return nil
		end
		local oil = require("oil")
		oil.setup({
			delete_to_trash = true,
			win_options = { signcolumn = "yes" },
			float = { max_width = 0.8, max_height = 0.8, border = "rounded" },
			preview_win = { update_on_cursor_moved = false },
			keymaps = {
				["-"] = { "actions.close", mode = "n" },
				["<BS>"] = { "actions.parent", mode = "n" },
				["<C-v>"] = { "actions.select", opts = { vertical = true } },
				["<C-x>"] = { "actions.select", opts = { horizontal = true } },
				["q"] = { "actions.close", mode = "n" },
				["<Esc>"] = { "actions.close", mode = "n" },
			},
		})
		local columns = require("oil.columns")
		local adapter = require("oil.config").get_adapter_by_scheme("oil://")
		local modified = vim.iter(vim.api.nvim_list_bufs()):any(function(buf)
			return vim.bo[buf].filetype == "oil" and vim.bo[buf].modified
		end)
		if not columns.get_column(adapter, "icon") and not modified then
			package.loaded["oil.columns"] = nil
			local icons = require("oil.columns").get_column(adapter, "icon")
			package.loaded["oil.columns"] = columns
			if icons then
				columns.register("icon", icons)
				oil.set_columns(require("oil.config").columns)
			end
		end
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.bo[buf].filetype == "oil" then
				require("oil.keymap_util").set_keymaps(require("oil.config").keymaps, buf)
				for _, win in ipairs(vim.fn.win_findbuf(buf)) do
					vim.wo[win].signcolumn = "yes"
				end
				refresh_git(buf)
			end
		end
		configured = true
		return oil
	end

	local function toggle()
		local oil = load()
		if oil then
			if vim.bo.filetype == "oil" then
				oil.close()
			else
				oil.toggle_float()
			end
		end
	end
	vim.keymap.set("n", "-", toggle, { desc = "Oil: Toggle explorer" })
	vim.keymap.set("n", "<leader>e", toggle, { desc = "Oil: Explore current directory" })
	vim.keymap.set("n", "<leader>fe", function()
		local oil = load()
		if oil then
			oil.open_float()
		end
	end, { desc = "Oil: Reveal current file's directory" })

	if package.loaded.oil then
		load()
	else
		vim.api.nvim_create_user_command("Oil", function(opts)
			local oil = load()
			if oil then
				oil.open(opts.args ~= "" and opts.args or nil)
			end
		end, { nargs = "?", complete = "dir", force = true, desc = "Open Oil in a normal window" })
	end
end

return M
