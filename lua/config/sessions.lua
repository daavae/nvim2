local util = require("config.util")

local M = {}

local session_dir = vim.fn.stdpath("state") .. "/sessions"

local function stable_hash(value)
	if vim.fn.executable("sha256sum") == 1 then
		return vim.fn.system({ "sha256sum" }, value):match("^%x+")
	elseif vim.fn.executable("shasum") == 1 then
		return vim.fn.system({ "shasum", "-a", "256" }, value):match("^%x+")
	end
	return vim.fn.sha256(value)
end

local function session_path()
	local root = vim.fs.normalize(util.current_project_root({ ".git" }))
	local basename = vim.fn.fnamemodify(root, ":t"):gsub("[^%w._-]", "_")
	local key = basename .. "-" .. stable_hash(root):sub(1, 16)
	return vim.fs.joinpath(session_dir, key .. ".vim"), root
end

local function ensure_session_dir()
	vim.fn.mkdir(session_dir, "p")
end

function M.setup()
	vim.opt.sessionoptions = {
		"buffers",
		"curdir",
		"folds",
		"help",
		"tabpages",
		"winsize",
		"winpos",
		"terminal",
	}

	vim.api.nvim_create_user_command("ProjectSessionStart", function()
		ensure_session_dir()
		local path, root = session_path()
		vim.cmd("Obsession " .. vim.fn.fnameescape(path))
		vim.notify("Tracking session for " .. root)
	end, { force = true, desc = "Start or resume this project's Obsession session" })

	vim.api.nvim_create_user_command("ProjectSessionLoad", function()
		local path, root = session_path()
		if vim.uv.fs_stat(path) == nil then
			vim.notify("No saved session for " .. root, vim.log.levels.WARN)
			return
		end
		vim.cmd("silent source " .. vim.fn.fnameescape(path))
		vim.notify("Loaded session for " .. root)
	end, { force = true, desc = "Load this project's saved session" })

	vim.api.nvim_create_user_command("ProjectSessionStop", function()
		if vim.fn.exists("g:this_obsession") == 1 then
			vim.cmd("Obsession")
			vim.notify("Paused project session tracking")
		else
			vim.notify("No project session is being tracked", vim.log.levels.INFO)
		end
	end, { force = true, desc = "Pause Obsession session tracking" })

	vim.api.nvim_create_user_command("ProjectSessionDelete", function()
		local path, root = session_path()
		if vim.fn.exists("g:this_obsession") == 1 and vim.g.this_obsession == path then
			vim.cmd("Obsession!")
		elseif vim.uv.fs_stat(path) then
			local ok, err = os.remove(path)
			if not ok then
				vim.notify("Could not delete session: " .. tostring(err), vim.log.levels.ERROR)
				return
			end
		else
			vim.notify("No saved session for " .. root, vim.log.levels.WARN)
			return
		end
		vim.notify("Deleted session for " .. root)
	end, { force = true, desc = "Delete this project's saved session" })
end

return M
