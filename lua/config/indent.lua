local M = {}

local function set_enabled(enabled)
	vim.g.miniindentscope_disable = not enabled
	if not enabled then
		require("mini.indentscope").undraw()
	end
	vim.o.list = enabled
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		vim.wo[win].list = enabled
	end
end

local function toggle()
	set_enabled(vim.g.miniindentscope_disable == true)
	vim.notify("Indent guides " .. (vim.g.miniindentscope_disable and "disabled" or "enabled"))
end

function M.setup()
	local indentscope = require("mini.indentscope")
	indentscope.setup({
		symbol = "┃",
		draw = { delay = 0, animation = indentscope.gen_animation.none() },
		options = { try_as_border = true },
	})
	set_enabled(vim.g.miniindentscope_disable ~= true)
	vim.api.nvim_create_autocmd("WinNew", {
		group = vim.api.nvim_create_augroup("UserConfigIndent", { clear = true }),
		callback = function()
			vim.wo.list = vim.g.miniindentscope_disable ~= true
		end,
	})
	vim.api.nvim_create_user_command("IndentGuidesToggle", toggle, { force = true, desc = "Toggle indent guides" })
	vim.keymap.set("n", "<leader>ig", toggle, { desc = "Toggle indent guides" })
end

return M
