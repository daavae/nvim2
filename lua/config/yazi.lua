local M = type(package.loaded["config.yazi"]) == "table" and package.loaded["config.yazi"] or {}

function M.setup(plugins)
	-- yazi.nvim owns directory buffers, so prevent netrw from claiming them first.
	vim.g.loaded_netrwPlugin = 1
	M.configured = M.configured or false

	local function grep(paths)
		local fzf = plugins.get_fzf()
		if fzf then
			fzf.live_grep({ search_paths = paths })
		end
	end

	local function load()
		if M.configured then
			return require("yazi")
		end
		if not plugins.ensure("plenary.nvim") or not plugins.ensure("yazi.nvim") then
			return nil
		end
		local yazi = require("yazi")
		yazi.setup({
			open_for_directories = true,
			open_multiple_tabs = true,
			floating_window_scaling_factor = 0.9,
			yazi_floating_window_border = "rounded",
			yazi_floating_window_winblend = 0,
			keymaps = {
				show_help = "<F1>",
				replace_in_directory = false,
				copy_relative_path_to_selected_files = false,
				open_and_pick_window = false,
			},
			integrations = {
				grep_in_directory = function(directory)
					grep({ directory })
				end,
				grep_in_selected_files = function(_, files)
					grep(files)
				end,
			},
		})
		M.configured = true
		return yazi
	end

	local function current()
		local yazi = load()
		if yazi then
			yazi.yazi()
		end
	end

	local function cwd()
		local yazi = load()
		if yazi then
			yazi.yazi(nil, vim.fn.getcwd())
		end
	end

	local function toggle()
		local yazi = load()
		if yazi then
			yazi.toggle()
		end
	end

	vim.keymap.set({ "n", "x" }, "-", current, { desc = "Yazi: Open at current file" })
	vim.keymap.set({ "n", "x" }, "<leader>e", current, { desc = "Yazi: Open at current file" })
	vim.keymap.set("n", "<leader>fe", cwd, { desc = "Yazi: Open working directory" })
	vim.keymap.set("n", "<leader>fE", toggle, { desc = "Yazi: Resume last session" })

	local group = vim.api.nvim_create_augroup("UserConfigYazi", { clear = true })
	if vim.v.vim_did_enter == 1 then
		load()
	else
		vim.api.nvim_create_autocmd("UIEnter", {
			group = group,
			once = true,
			callback = load,
		})
	end
end

return M
