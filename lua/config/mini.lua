local M = {}

function M.setup()
	require("mini.clue").setup({
		window = {
			delay = 0,
			config = { width = "auto", border = "rounded", row = "auto", col = "auto" },
		},
		triggers = {
			{ mode = { "n", "x" }, keys = "<Leader>" },
			{ mode = { "n", "x" }, keys = "g" },
			{ mode = "n", keys = "z" },
			{ mode = "n", keys = "[" },
			{ mode = "n", keys = "]" },
			{ mode = { "n", "x" }, keys = "'" },
			{ mode = { "n", "x" }, keys = "`" },
			{ mode = { "n", "x" }, keys = '"' },
			{ mode = { "i", "c" }, keys = "<C-r>" },
		},
		clues = {
			require("mini.clue").gen_clues.builtin_completion(),
			require("mini.clue").gen_clues.g(),
			require("mini.clue").gen_clues.marks(),
			require("mini.clue").gen_clues.registers(),
			require("mini.clue").gen_clues.windows(),
			require("mini.clue").gen_clues.z(),
		},
	})
	require("mini.ai").setup({})
	require("mini.surround").setup({
		mappings = {
			add = "gsa",
			delete = "gsd",
			find = "gsf",
			find_left = "gsF",
			highlight = "gsh",
			replace = "gsr",
			update_n_lines = "gsn",
			suffix_last = "l",
			suffix_next = "n",
		},
	})
	require("mini.notify").setup({})
end

return M
