local M = {}
local tasks = rawget(_G, "__config_project_tasks") or {}
_G.__config_project_tasks = tasks
M.tasks = tasks

local function set_title(state, status)
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		local name = vim.fn.fnamemodify(state.root, ":t")
		vim.wo[state.win].winbar = (" Task: %s [%s] "):format(name, status)
	end
end

local function finish(state, generation, code)
	if state.generation ~= generation then
		return
	end
	state.job = nil
	state.last_exit = code
	state.duration_ms = math.floor((vim.uv.hrtime() - state.started_at) / 1e6)
	set_title(state, code == 0 and "done" or ("failed:%d"):format(code))
	vim.notify(
		("Task %s (code %d, %dms)"):format(code == 0 and "finished" or "failed", code, state.duration_ms),
		code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR,
		{ title = vim.fn.fnamemodify(state.root, ":t") }
	)
end

local function open_window(state)
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_set_current_win(state.win)
		return
	end
	vim.cmd("botright 15split")
	state.win = vim.api.nvim_get_current_win()
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_win_set_buf(state.win, state.buf)
	end
end

local function start(state, args)
	state.generation = (state.generation or 0) + 1
	local generation = state.generation
	open_window(state)

	local old_buf = state.buf
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(state.win, buf)
	vim.bo[buf].bufhidden = "hide"
	vim.b[buf].task_root = state.root
	state.buf = buf
	if old_buf and vim.api.nvim_buf_is_valid(old_buf) then
		pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
	end

	local command = { "sh", state.script }
	vim.list_extend(command, args or {})
	state.started_at = vim.uv.hrtime()
	state.last_exit = nil
	state.duration_ms = nil
	set_title(state, "running")

	local jobid = vim.fn.jobstart(command, {
		term = true,
		cwd = state.root,
		on_exit = function(_, code)
			vim.schedule(function()
				finish(state, generation, code)
			end)
		end,
	})

	if jobid <= 0 then
		set_title(state, "failed:start")
		vim.notify("Failed to start " .. state.script, vim.log.levels.ERROR)
		return
	end
	state.job = jobid
	vim.b[buf].terminal_job_id = jobid
	-- A very short task can exit before jobstart() returns and sets state.job.
	-- Reconcile that race without mistaking a completed job for a running one.
	vim.schedule(function()
		if state.generation == generation and state.last_exit ~= nil then
			state.job = nil
		end
	end)
	vim.cmd("startinsert")
end

local function save_current_buffer()
	local buf = vim.api.nvim_get_current_buf()
	if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or not vim.bo[buf].modified then
		return
	end
	vim.g.__skip_update_remote = true
	local ok, err = pcall(vim.cmd, "silent write")
	vim.g.__skip_update_remote = false
	if not ok then
		error(err)
	end
end

local function locate_task()
	local start = vim.b.task_root or vim.api.nvim_buf_get_name(0)
	if start == "" then
		start = vim.fn.getcwd()
	elseif vim.fn.isdirectory(start) ~= 1 then
		start = vim.fs.dirname(start)
	end
	local script = vim.fs.find("run.sh", { upward = true, path = start })[1]
	return script, script and vim.fs.dirname(script) or nil
end

local function run(opts)
	save_current_buffer()
	local script, root = locate_task()
	if not script or not root then
		vim.notify("run.sh not found", vim.log.levels.WARN)
		return
	end

	local state = tasks[root] or { root = root, script = script }
	tasks[root] = state
	if state.job then
		if not opts.bang then
			open_window(state)
			vim.notify("Task is already running; use :Run! to restart it", vim.log.levels.INFO)
			return
		end
		local old_job = state.job
		vim.fn.jobstop(old_job)
		if vim.fn.jobwait({ old_job }, 1000)[1] == -1 then
			vim.notify("Task did not stop within one second; restart canceled", vim.log.levels.ERROR)
			return
		end
		state.generation = (state.generation or 0) + 1
		state.job = nil
	end
	start(state, opts.fargs)
end

local function current_task()
	local root = vim.b.task_root
	if root and tasks[root] then
		return tasks[root]
	end
	local _, detected_root = locate_task()
	return detected_root and tasks[detected_root] or nil
end

function M.setup()
	vim.api.nvim_create_user_command("Run", run, {
		bang = true,
		nargs = "*",
		force = true,
		desc = "Run project run.sh; use ! to restart",
	})
	vim.api.nvim_create_user_command("RunStop", function()
		local state = current_task()
		if not state or not state.job then
			vim.notify("No project task is running", vim.log.levels.INFO)
			return
		end
		local job = state.job
		vim.fn.jobstop(job)
		if vim.fn.jobwait({ job }, 1000)[1] == -1 then
			vim.notify("Task did not stop within one second", vim.log.levels.ERROR)
			return
		end
		state.generation = (state.generation or 0) + 1
		state.job = nil
		set_title(state, "stopped")
	end, { force = true, desc = "Stop the current project task" })
end

return M
