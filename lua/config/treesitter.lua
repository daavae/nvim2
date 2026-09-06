local M = {}

local parsers = {
	"vim",
	"vimdoc",
	"rust",
	"c",
	"cpp",
	"go",
	"html",
	"css",
	"javascript",
	"json",
	"lua",
	"markdown",
	"python",
	"typescript",
	"vue",
	"svelte",
	"bash",
}

function M.setup()
	local treesitter = require("nvim-treesitter")
	treesitter.setup({})

	local installed = require("nvim-treesitter.config").get_installed("parsers")
	local missing = {}
	for _, parser in ipairs(parsers) do
		if not vim.tbl_contains(installed, parser) then
			missing[#missing + 1] = parser
		end
	end
	if #missing > 0 then
		treesitter.install(missing)
	end

	local group = vim.api.nvim_create_augroup("TreeSitterConfig", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		callback = function(args)
			local language = vim.treesitter.language.get_lang(args.match)
			if language and vim.list_contains(treesitter.get_installed("parsers"), language) then
				pcall(vim.treesitter.start, args.buf)
			end
		end,
	})

	require("treesitter-context").setup({})
end

return M
