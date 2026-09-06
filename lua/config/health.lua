local util = require("config.util")

local M = {}

local tools = {
	{ "rg", "file and text search" },
	{ "fzf", "fuzzy finder" },
	{ "git", "Git integration" },
	{ "lazygit", "LazyGit UI" },
	{ "node", "JavaScript language tooling" },
	{ "lua-language-server", "Lua LSP" },
	{ "pyright-langserver", "Python LSP" },
	{ "bash-language-server", "Shell LSP" },
	{ "typescript-language-server", "TypeScript LSP" },
	{ "gopls", "Go LSP" },
	{ "clangd", "C/C++ LSP" },
	{ "efm-langserver", "formatting and linting LSP" },
	{ "stylua", "Lua formatter" },
	{ "luacheck", "Lua linter" },
	{ "black", "Python formatter" },
	{ "prettierd", "web formatter" },
	{ "eslint_d", "JavaScript and TypeScript linter" },
	{ "fixjson", "JSON formatter" },
	{ "shellcheck", "shell linter" },
	{ "shfmt", "shell formatter" },
	{ "gofumpt", "Go formatter" },
	{ "revive", "Go linter" },
	{ "clang-format", "C/C++ formatter" },
	{ "cpplint", "C/C++ linter" },
}

local function tool_line(tool)
	local path = vim.fn.exepath(tool[1])
	if path == "" and tool[3] and vim.fn.executable(tool[3]) == 1 then
		path = tool[3]
	end
	local mark = path ~= "" and "OK" or "MISSING"
	return ("%-7s %-28s %s"):format(mark, tool[1], path ~= "" and path or tool[2])
end

local function clipboard_line()
	if vim.fn.has("clipboard") == 1 then
		return "OK      clipboard                    built into Neovim"
	end
	for _, executable in ipairs({ "pbcopy", "wl-copy", "xclip", "xsel" }) do
		if vim.fn.executable(executable) == 1 then
			return "OK      clipboard provider           " .. vim.fn.exepath(executable)
		end
	end
	return "MISSING clipboard provider           install wl-clipboard, xclip, or xsel on Linux"
end

local function sound_line()
	local sysname = vim.uv.os_uname().sysname
	local candidates = sysname == "Darwin" and { "afplay" } or { "canberra-gtk-play", "paplay", "aplay" }
	for _, executable in ipairs(candidates) do
		if vim.fn.executable(executable) == 1 then
			return "OK      sound backend                " .. vim.fn.exepath(executable)
		end
	end
	return "OPTION  sound backend                terminal bell fallback"
end

local function parser_lines()
	local ok, treesitter = pcall(require, "nvim-treesitter")
	if not ok then
		return { "ERROR   treesitter                   plugin unavailable" }
	end
	local installed = treesitter.get_installed()
	return {
		("OK      treesitter parsers           %d installed"):format(#installed),
		"        " .. table.concat(installed, ", "),
	}
end

function M.setup()
	vim.api.nvim_create_user_command("ConfigHealth", function()
		local lines = {
			"Neovim config health",
			"====================",
			"",
			("Neovim: %d.%d.%d"):format(vim.version().major, vim.version().minor, vim.version().patch),
			"OS:     " .. vim.uv.os_uname().sysname .. " " .. vim.uv.os_uname().machine,
			"Config: " .. vim.fn.stdpath("config"),
			"Data:   " .. vim.fn.stdpath("data"),
			"",
			"External tools",
			"--------------",
		}
		for _, tool in ipairs(tools) do
			lines[#lines + 1] = tool_line(tool)
		end
		lines[#lines + 1] = clipboard_line()
		lines[#lines + 1] = sound_line()
		lines[#lines + 1] = ""
		lines[#lines + 1] = "Treesitter"
		lines[#lines + 1] = "----------"
		vim.list_extend(lines, parser_lines())
		util.open_scratch("config-health://report", lines, "text")
	end, { force = true, desc = "Show external-tool and Treesitter health" })
end

return M
