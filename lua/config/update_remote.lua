local util = require("config.util")

local M = {}
local jobs = rawget(_G, "__config_update_remote_jobs") or {}
_G.__config_update_remote_jobs = jobs
local max_output_lines = 200
M.jobs = jobs

local function append_lines(target, data)
	if not data or data == "" then
		return
	end
	vim.list_extend(target, vim.split(data, "\n", { trimempty = true }))
	if #target > max_output_lines then
		target = vim.list_slice(target, #target - max_output_lines + 1)
	end
	return target
end

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
	state.code = nil
	state.duration_ms = nil
	state.finished_at = nil
	state.stdout = {}
	state.stderr = {}

	state.process = vim.system({ "sh", script }, { cwd = root, text = true }, function(result)
		local duration_ms = math.floor((vim.uv.hrtime() - state.started_at) / 1e6)
		vim.schedule(function()
			if state.generation ~= generation then
				return
			end
			state.process = nil
			state.code = result.code
			state.duration_ms = duration_ms
			state.finished_at = os.time()
			state.stdout = append_lines(state.stdout, result.stdout) or state.stdout
			state.stderr = append_lines(state.stderr, result.stderr) or state.stderr
			util.play_completion_sound(result.code == 0)
			local name = vim.fn.fnamemodify(root, ":t")
			local message
			local level
			if result.code == 0 then
				message = ("update_remote finished (%dms)"):format(duration_ms)
				level = vim.log.levels.INFO
			else
				local details = util.tail(state.stderr, 6)
				message = ("update_remote failed (code %d, %dms)"):format(result.code, duration_ms)
				if #details > 0 then
					message = message .. "\n" .. table.concat(details, "\n")
				end
				level = vim.log.levels.ERROR
			end
			vim.notify(message, level, { title = name })

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

local function current_state()
	local script, root = find_script(vim.api.nvim_buf_get_name(0))
	if not root then
		return nil, nil, script
	end
	return jobs[root], root, script
end

local function show_status()
	local state, root, script = current_state()
	if not root then
		vim.notify("No update_remote.sh found for the current buffer", vim.log.levels.WARN)
		return
	end

	local lines = {
		"Update remote",
		"=============",
		"",
		"Root:   " .. root,
		"Script: " .. script,
	}
	if not state then
		lines[#lines + 1] = "Status: never run in this Neovim session"
	else
		lines[#lines + 1] = "Status: " .. (state.process and "running" or "finished")
		lines[#lines + 1] = "Queued rerun: " .. tostring(state.pending == true)
		if state.code ~= nil then
			lines[#lines + 1] = ("Last exit: %d (%dms)"):format(state.code, state.duration_ms or 0)
		end
		local output = #state.stderr > 0 and state.stderr or state.stdout
		if #output > 0 then
			lines[#lines + 1] = ""
			lines[#lines + 1] = #state.stderr > 0 and "Last stderr:" or "Last output:"
			vim.list_extend(lines, util.tail(output, 30))
		end
	end
	util.open_scratch("update-remote://status", lines, "text")
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
	vim.api.nvim_create_user_command("UpdateRemoteStatus", show_status, {
		force = true,
		desc = "Show the latest update_remote result",
	})
end

return M
