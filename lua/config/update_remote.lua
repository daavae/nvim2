local util = require("config.util")

local M = {}
local jobs = rawget(_G, "__config_update_remote_jobs") or {}
_G.__config_update_remote_jobs = jobs
M.jobs = jobs

local function find_script(path)
	local dir = path and path ~= "" and vim.fs.dirname(path) or vim.fn.getcwd()
	if not dir or dir == "" then
		return nil, nil
	end
	local script = vim.fs.find("update_remote.sh", { upward = true, path = dir })[1]
	return script, script and vim.fs.dirname(script) or nil
end

local start_job
start_job = function(root, script)
	local state = jobs[root] or {}
	jobs[root] = state
	state.generation = (state.generation or 0) + 1
	local generation = state.generation
	state.pending = false
	state.started_at = vim.uv.hrtime()

	state.process = vim.system({ "sh", script }, { cwd = root, text = true }, function(result)
		local duration_ms = math.floor((vim.uv.hrtime() - state.started_at) / 1e6)
		vim.schedule(function()
			if state.generation ~= generation then
				return
			end
			state.process = nil
			local message, level
			if result.code == 0 then
				message = ("update_remote finished (%dms)"):format(duration_ms)
				level = vim.log.levels.INFO
			else
				local details = util.tail(vim.split(result.stderr or "", "\n", { trimempty = true }), 6)
				message = ("update_remote failed (code %d, %dms)"):format(result.code, duration_ms)
				if #details > 0 then
					message = message .. "\n" .. table.concat(details, "\n")
				end
				level = vim.log.levels.ERROR
			end
			vim.notify(message, level, { title = vim.fn.fnamemodify(root, ":t") })
			vim.api.nvim_exec_autocmds("User", {
				pattern = "UpdateRemoteFinished",
				modeline = false,
				data = { root = root, script = script, code = result.code, duration_ms = duration_ms },
			})

			if state.pending and state.process == nil then
				start_job(root, script)
			end
		end)
	end)
end

local function enqueue(path)
	local script, root = find_script(path)
	if not script or not root then
		return false
	end

	local state = jobs[root]
	if state and state.process then
		state.pending = true
		return true
	end

	start_job(root, script)
	return true
end

function M.setup()
	local group = vim.api.nvim_create_augroup("UserConfigUpdateRemote", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		callback = function(args)
			if vim.g.__skip_update_remote == true or vim.bo[args.buf].buftype ~= "" then
				return
			end
			local path = vim.api.nvim_buf_get_name(args.buf)
			if path ~= "" then
				enqueue(path)
			end
		end,
	})

	vim.api.nvim_create_user_command("UpdateRemote", function()
		if not enqueue(vim.api.nvim_buf_get_name(0)) then
			vim.notify("No update_remote.sh found for the current buffer", vim.log.levels.WARN)
		end
	end, { force = true, desc = "Run or queue update_remote.sh" })
end

return M
