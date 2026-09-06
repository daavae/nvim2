local M = {}

function M.project_root(start_path, markers)
	local start = start_path
	if not start or start == "" then
		start = vim.fn.getcwd()
	elseif vim.fn.isdirectory(start) ~= 1 then
		start = vim.fs.dirname(start)
	end

	if not start or start == "" then
		return vim.fn.getcwd()
	end

	for _, marker in ipairs(markers or { ".git" }) do
		local found = vim.fs.find(marker, { upward = true, path = start })[1]
		if found then
			return vim.fs.dirname(found)
		end
	end

	return start
end

function M.current_project_root(markers)
	local bufname = vim.api.nvim_buf_get_name(0)
	local task_root = vim.b.task_root
	return M.project_root(task_root or bufname, markers)
end

function M.tail(lines, limit)
	local output = {}
	for _, line in ipairs(lines or {}) do
		if line and line ~= "" then
			output[#output + 1] = line
		end
	end
	if #output <= limit then
		return output
	end
	return vim.list_slice(output, #output - limit + 1)
end

local function executable_command(candidates)
	for _, candidate in ipairs(candidates) do
		local executable = candidate.command[1]
		if vim.fn.executable(executable) == 1 and (not candidate.file or vim.uv.fs_stat(candidate.file)) then
			return candidate.command
		end
	end
end

function M.play_completion_sound(success)
	local sysname = vim.uv.os_uname().sysname
	local command

	if sysname == "Darwin" then
		local sound = success and "/System/Library/Sounds/Glass.aiff" or "/System/Library/Sounds/Basso.aiff"
		command = executable_command({ { command = { "afplay", sound }, file = sound } })
	elseif sysname == "Linux" then
		local event = success and "complete" or "dialog-error"
		local sound = success and "complete.oga" or "dialog-error.oga"
		local pulse_file = "/usr/share/sounds/freedesktop/stereo/" .. sound
		command = executable_command({
			{ command = { "canberra-gtk-play", "-i", event } },
			{ command = { "paplay", pulse_file }, file = pulse_file },
			{
				command = { "aplay", "/usr/share/sounds/alsa/Front_Center.wav" },
				file = "/usr/share/sounds/alsa/Front_Center.wav",
			},
		})
	end

	if command then
		vim.fn.jobstart(command, { detach = true })
	else
		-- Works when the terminal has an audible or visual bell enabled.
		vim.api.nvim_out_write("\7")
	end
end

function M.open_scratch(title, lines, filetype)
	for _, existing in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(existing) and vim.api.nvim_buf_get_name(existing) == title then
			vim.bo[existing].modifiable = true
			vim.api.nvim_buf_set_lines(existing, 0, -1, false, lines)
			vim.bo[existing].modifiable = false
			vim.bo[existing].filetype = filetype or "text"
			vim.api.nvim_set_current_buf(existing)
			return existing
		end
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, title)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = filetype or "text"
	vim.api.nvim_set_current_buf(buf)
	vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, desc = "Close" })
	return buf
end

return M
