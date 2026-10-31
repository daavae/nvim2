local M = {}

function M.setup(plugins)
	vim.keymap.set("n", "<leader>mv", function()
		if not plugins.get_markview() then
			return
		end
		local buf = vim.api.nvim_get_current_buf()
		local actions = require("markview.actions")
		if require("markview.state").buf_attached(buf) then
			actions.toggle(buf)
		else
			actions.attach(buf)
		end
	end, { desc = "Toggle markdown view" })
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("UserConfigMarkdown", { clear = true }),
		pattern = { "markdown", "text", "gitcommit" },
		callback = function()
			vim.opt_local.wrap = true
			vim.opt_local.linebreak = true
			vim.opt_local.spell = true
		end,
	})
end

return M
