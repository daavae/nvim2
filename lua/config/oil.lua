local M = {}

-- oil.nvim ships a built-in SSH adapter (oil-ssh://[user@]host[:port]/[path]);
-- it requires a trailing "/" after the host even with no path given.
local function ssh_url(target)
	target = target:gsub("^oil%-ssh://", "")
	if not target:find("/") then
		target = target .. "/"
	end
	return "oil-ssh://" .. target
end

-- Last SSH target used via :OilSsh/<leader>es, and whether "-"/<leader>e/
-- <leader>fe currently resolve to it instead of the local filesystem.
-- Toggled with <leader>et.
local active_remote = nil
local remote_mode = false

local function current_directory()
	local path = vim.api.nvim_buf_get_name(0)
	local buftype = vim.bo.buftype
	-- oil's own file buffers (local AND remote/virtual) use buftype "acwrite"
	-- so :w can be intercepted (e.g. scp'd back for ssh); they still have a
	-- real, meaningful directory and shouldn't be treated as "no directory"
	-- the way a terminal or quickfix buffer would be.
	if path ~= "" and (buftype == "" or buftype == "acwrite") then
		return vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
	end
	if remote_mode and active_remote then
		return ssh_url(active_remote)
	end
	return vim.fn.getcwd()
end

function M.setup(plugins)
	local configured = false
	local preview_timers = {}
	local git_generations = {}
	local git_namespace = vim.api.nvim_create_namespace("OilGitStatus")

	local git_signs = {
		added = { text = "+", hl = "DiagnosticOk" },
		modified = { text = "~", hl = "DiagnosticWarn" },
		deleted = { text = "-", hl = "DiagnosticError" },
		untracked = { text = "?", hl = "DiagnosticInfo" },
		conflict = { text = "!", hl = "DiagnosticError" },
	}

	local function status_kind(code)
		if code == "??" then
			return "untracked"
		elseif code:find("U", 1, true) or code == "AA" or code == "DD" then
			return "conflict"
		elseif code:find("D", 1, true) then
			return "deleted"
		elseif code:find("A", 1, true) then
			return "added"
		end
		return "modified"
	end

	local function render_git_signs(buf, status)
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		vim.api.nvim_buf_clear_namespace(buf, git_namespace, 0, -1)
		for line = 1, vim.api.nvim_buf_line_count(buf) do
			local entry = require("oil").get_entry_on_line(buf, line)
			if entry then
				local key = entry.name .. (entry.type == "directory" and "/" or "")
				local kind = status[key] or status[entry.name]
				if kind then
					local sign = git_signs[kind]
					vim.api.nvim_buf_set_extmark(buf, git_namespace, line - 1, 0, {
						sign_text = sign.text,
						sign_hl_group = sign.hl,
						priority = 20,
					})
				end
			end
		end
	end

	local function refresh_git_status(buf)
		local dir = require("oil").get_current_dir(buf)
		if not dir or vim.fn.executable("git") ~= 1 then
			return
		end
		git_generations[buf] = (git_generations[buf] or 0) + 1
		local generation = git_generations[buf]
		vim.system(
			{ "git", "status", "--porcelain=v1", "-z", "--untracked-files=all" },
			{ cwd = dir, text = true },
			function(result)
				local status = {}
				if result.code == 0 then
					local records = vim.split(result.stdout or "", "\0", { plain = true, trimempty = true })
					local index = 1
					while index <= #records do
						local record = records[index]
						local code, path = record:sub(1, 2), record:sub(4)
						local kind = status_kind(code)
						status[path] = kind
						if code:find("R", 1, true) or code:find("C", 1, true) then
							index = index + 1
							local old_path = records[index]
							if old_path then
								status[old_path] = "deleted"
							end
						end
						local top = path:match("^([^/]+)/")
						if top and not status[top .. "/"] then
							status[top .. "/"] = kind
						end
						index = index + 1
					end
				end
				vim.schedule(function()
					if git_generations[buf] == generation then
						render_git_signs(buf, status)
					end
				end)
			end
		)
	end

	local function enable_hover_preview(buf)
		local group = vim.api.nvim_create_augroup("UserConfigOilPreview" .. buf, { clear = true })
		local function preview_file()
			local entry = require("oil").get_cursor_entry()
			if not entry or entry.type ~= "file" then
				return
			end
			local timer = preview_timers[buf]
			if timer then
				timer:stop()
			else
				timer = vim.uv.new_timer()
				preview_timers[buf] = timer
			end
			timer:start(
				80,
				0,
				vim.schedule_wrap(function()
					if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
						require("oil").open_preview({ vertical = true })
					end
				end)
			)
		end

		vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
			group = group,
			buffer = buf,
			callback = preview_file,
		})
		vim.api.nvim_create_autocmd("BufWipeout", {
			group = group,
			buffer = buf,
			once = true,
			callback = function()
				git_generations[buf] = nil
				local timer = preview_timers[buf]
				if timer then
					timer:stop()
					timer:close()
					preview_timers[buf] = nil
				end
			end,
		})
		preview_file()
	end

	local function load()
		if configured then
			return require("oil")
		end
		if not plugins.ensure("oil.nvim") then
			return nil
		end

		local oil = require("oil")
		oil.setup({
			default_file_explorer = true,
			columns = { "icon" },
			win_options = {
				signcolumn = "yes",
			},
			delete_to_trash = true,
			skip_confirm_for_simple_edits = false,
			prompt_save_on_select_new_entry = true,
			cleanup_delay_ms = 2000,
			lsp_file_methods = {
				timeout_ms = 1000,
				autosave_changes = false,
			},
			constrain_cursor = "editable",
			watch_for_changes = true,
			view_options = {
				show_hidden = true,
				natural_order = true,
				is_always_hidden = function(name)
					return name == ".."
				end,
			},
			float = {
				padding = 2,
				max_width = 0.8,
				max_height = 0.8,
				border = "rounded",
				win_options = { winblend = 0 },
			},
			preview_win = {
				update_on_cursor_moved = false,
				preview_method = "fast_scratch",
				win_options = {
					wrap = false,
					number = true,
					relativenumber = false,
				},
			},
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				["<CR>"] = "actions.select",
				["<C-v>"] = { "actions.select", opts = { vertical = true } },
				["<C-x>"] = { "actions.select", opts = { horizontal = true } },
				["<C-t>"] = { "actions.select", opts = { tab = true } },
				["<C-p>"] = "actions.preview",
				["q"] = { "actions.close", mode = "n" },
				["<Esc>"] = { "actions.close", mode = "n" },
				["-"] = { "actions.parent", mode = "n" },
				["_"] = { "actions.open_cwd", mode = "n" },
				["`"] = { "actions.cd", mode = "n" },
				["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
				["gs"] = { "actions.change_sort", mode = "n" },
				["gx"] = "actions.open_external",
				["g."] = { "actions.toggle_hidden", mode = "n" },
				["g\\"] = { "actions.toggle_trash", mode = "n" },
			},
		})
		local function oil_buffer(buf)
			vim.defer_fn(function()
				if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "oil" then
					-- Auto-preview fires on every cursor move; over a remote
					-- (ssh) adapter each preview is its own network fetch, and
					-- fast movement can race two fetches against the same
					-- preview buffer, crashing oil's read_file callback.
					-- get_current_dir() only returns non-nil for local dirs.
					if require("oil").get_current_dir(buf) then
						enable_hover_preview(buf)
					end
					refresh_git_status(buf)
				end
			end, 20)
		end
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("UserConfigOil", { clear = true }),
			pattern = "oil",
			callback = function(args)
				oil_buffer(args.buf)
			end,
		})
		vim.api.nvim_create_autocmd("User", {
			group = vim.api.nvim_create_augroup("UserConfigOilGit", { clear = true }),
			pattern = { "OilEnter", "OilActionsPost" },
			callback = function(args)
				local buf = args.data and args.data.buf or vim.api.nvim_get_current_buf()
				if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "oil" then
					refresh_git_status(buf)
				end
			end,
		})
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.bo[buf].filetype == "oil" then
				oil_buffer(buf)
			end
		end
		configured = true
		return oil
	end

	local function open_with_preview(open)
		local oil = load()
		if not oil then
			return
		end
		open(oil)
	end

	vim.keymap.set("n", "-", function()
		open_with_preview(function(oil)
			oil.open(current_directory())
		end)
	end, { desc = "Oil: Open parent directory with preview" })

	vim.keymap.set("n", "<leader>e", function()
		open_with_preview(function(oil)
			oil.toggle_float(current_directory())
		end)
	end, { desc = "Oil: Explore current directory" })

	vim.keymap.set("n", "<leader>fe", function()
		open_with_preview(function(oil)
			oil.open_float(current_directory())
		end)
	end, { desc = "Oil: Reveal current file's directory" })

	vim.api.nvim_create_user_command("Oil", function(opts)
		open_with_preview(function(oil)
			oil.open(opts.args ~= "" and opts.args or current_directory())
		end)
	end, { nargs = "?", complete = "dir", force = true, desc = "Open Oil in a normal window" })

	local function open_ssh(target)
		active_remote = target
		remote_mode = true
		open_with_preview(function(oil)
			oil.open(ssh_url(target))
		end)
	end

	vim.api.nvim_create_user_command("OilSsh", function(opts)
		if opts.args == "" then
			vim.notify("Usage: :OilSsh [user@]host[:port][/path]", vim.log.levels.WARN)
			return
		end
		open_ssh(opts.args)
	end, { nargs = "?", force = true, desc = "Open Oil over SSH: [user@]host[:port][/path]" })

	vim.keymap.set("n", "<leader>es", function()
		vim.ui.input({ prompt = "SSH host ([user@]host[:port][/path]): ", default = active_remote or "" }, function(input)
			if input == nil or input == "" then
				return
			end
			open_ssh(input)
		end)
	end, { desc = "Oil: Open over SSH" })

	-- Flip whether "-"/<leader>e/<leader>fe resolve to the local filesystem or
	-- to the last SSH target, and jump straight there.
	vim.keymap.set("n", "<leader>et", function()
		if not active_remote then
			vim.notify("Oil: no SSH target yet - use <leader>es or :OilSsh first", vim.log.levels.WARN)
			return
		end
		remote_mode = not remote_mode
		if remote_mode then
			vim.notify("Oil: '-' now targets " .. active_remote)
			open_with_preview(function(oil)
				oil.open(ssh_url(active_remote))
			end)
		else
			vim.notify("Oil: '-' back to local filesystem")
			open_with_preview(function(oil)
				oil.open(vim.fn.getcwd())
			end)
		end
	end, { desc = "Oil: Toggle '-' between local and last SSH target" })
end

return M
