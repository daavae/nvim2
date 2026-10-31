local M = {}

local function prepend_to_path(path)
	if not path or path == "" or vim.fn.isdirectory(path) ~= 1 then
		return
	end

	local current_path = vim.env.PATH or ""
	for entry in current_path:gmatch("([^:]+)") do
		if entry == path then
			return
		end
	end
	vim.env.PATH = current_path == "" and path or path .. ":" .. current_path
end

local function ensure_node_in_path()
	if vim.fn.executable("node") == 1 then
		return
	end

	local home = vim.env.HOME or ""
	local nvm_bins = vim.fn.glob(home .. "/.nvm/versions/node/*/bin", false, true)
	-- Numeric ordering keeps v9 from taking precedence over v20.
	table.sort(nvm_bins, function(a, b)
		local a_version = a:match("/v(%d+)[^/]*/bin$")
		local b_version = b:match("/v(%d+)[^/]*/bin$")
		if a_version and b_version then
			return tonumber(a_version) > tonumber(b_version)
		end
		return a > b
	end)

	for _, bin in ipairs(nvm_bins) do
		prepend_to_path(bin)
		if vim.fn.executable("node") == 1 then
			return
		end
	end

	local sysname = vim.uv.os_uname().sysname
	if sysname == "Darwin" then
		prepend_to_path("/opt/homebrew/bin")
	elseif sysname == "Linux" then
		prepend_to_path("/home/linuxbrew/.linuxbrew/bin")
	end
	prepend_to_path("/usr/local/bin")
end

function M.setup()
	vim.loader.enable()
	prepend_to_path(vim.fn.stdpath("data") .. "/mason/bin")
	ensure_node_in_path()
end

return M
