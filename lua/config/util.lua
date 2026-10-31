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

return M
