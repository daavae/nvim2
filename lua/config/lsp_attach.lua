local M = {}

local function on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local opts = { noremap = true, silent = true, buffer = bufnr }
	local function with_desc(desc)
		return vim.tbl_extend("force", opts, { desc = desc })
	end

	if not vim.b[bufnr].lsp_buffer_setup_done then
		vim.b[bufnr].lsp_buffer_setup_done = true
		vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, with_desc("Go to definition"))
		vim.keymap.set("n", "<leader>gS", function()
			vim.cmd("vsplit")
			vim.lsp.buf.definition()
		end, with_desc("Definition (vsplit)"))
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, with_desc("Code action"))
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, with_desc("Rename symbol"))
		vim.keymap.set("n", "<leader>dl", function()
			vim.diagnostic.open_float({ scope = "line" })
		end, with_desc("Diagnostics (line)"))
		vim.keymap.set("n", "<leader>d", function()
			vim.diagnostic.open_float({ scope = "cursor" })
		end, with_desc("Diagnostics (cursor)"))
		vim.keymap.set("n", "K", vim.lsp.buf.hover, with_desc("Hover"))
		vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, with_desc("Signature help"))
		vim.keymap.set("n", "<leader>fd", function()
			local fzf = require("config.plugins").get_fzf()
			if fzf then
				fzf.lsp_definitions({ jump_to_single_result = true })
			end
		end, with_desc("Definitions (picker)"))
		vim.keymap.set("n", "<leader>fr", function()
			local fzf = require("config.plugins").get_fzf()
			if fzf then
				fzf.lsp_references()
			end
		end, with_desc("References (picker)"))
		vim.keymap.set("n", "<leader>ft", function()
			local fzf = require("config.plugins").get_fzf()
			if fzf then
				fzf.lsp_typedefs()
			end
		end, with_desc("Type definitions (picker)"))
		vim.keymap.set("n", "<leader>fs", function()
			local fzf = require("config.plugins").get_fzf()
			if fzf then
				fzf.lsp_document_symbols()
			end
		end, with_desc("Document symbols (picker)"))
		vim.keymap.set("n", "<leader>fw", function()
			local fzf = require("config.plugins").get_fzf()
			if fzf then
				fzf.lsp_workspace_symbols()
			end
		end, with_desc("Workspace symbols (picker)"))
		vim.keymap.set("n", "<leader>fi", function()
			local fzf = require("config.plugins").get_fzf()
			if fzf then
				fzf.lsp_implementations()
			end
		end, with_desc("Implementations (picker)"))
	end

	if client:supports_method("textDocument/codeAction", bufnr) and not vim.b[bufnr].lsp_organize_imports_set then
		vim.b[bufnr].lsp_organize_imports_set = true
		vim.keymap.set("n", "<leader>oi", function()
			vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
		end, with_desc("Organize imports"))
	end
	if client:supports_method("textDocument/completion", bufnr) then
		vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
	end
end

function M.setup()
	-- Nvim's completion re-enables the first client on buffer reload (:checktime) using its
	-- saved ID; if that client was stopped (e.g. :LspRestart) the assert errors. Skip dead IDs.
	local completion = vim.lsp.completion
	if not completion._dead_client_guard then
		completion._dead_client_guard = true
		local enable = completion.enable
		completion.enable = function(on, client_id, ...)
			if on and not vim.lsp.get_client_by_id(client_id) then
				return
			end
			return enable(on, client_id, ...)
		end
	end
	vim.keymap.set("i", "<C-Space>", function()
		vim.lsp.completion.get()
	end, { desc = "Trigger completion" })
	vim.keymap.set("i", "<CR>", function()
		if vim.fn.pumvisible() ~= 1 then
			return "<CR>"
		end
		return vim.fn.complete_info({ "selected" }).selected == -1 and "<C-e><CR>" or "<C-y>"
	end, { expr = true, desc = "Accept completion or insert newline" })
	local group = vim.api.nvim_create_augroup("UserConfigLspAttach", { clear = true })
	vim.api.nvim_create_autocmd("LspAttach", { group = group, callback = on_attach })
	-- Nvim only re-pulls a buffer's diagnostics when that buffer changes. Servers like tsgo
	-- report interFileDependencies but never send workspace/diagnostic/refresh, so fixing an
	-- error in one file left stale errors in the others until :LspRestart. Re-pull them all
	-- shortly after any edit.
	M.refresh_timers = M.refresh_timers or {}
	vim.api.nvim_create_autocmd("LspNotify", {
		group = group,
		callback = function(args)
			if args.data.method ~= "textDocument/didChange" then
				return
			end
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if
				not (client and vim.tbl_get(client.server_capabilities, "diagnosticProvider", "interFileDependencies"))
			then
				return
			end
			local timer = M.refresh_timers[client.id] or vim.uv.new_timer()
			M.refresh_timers[client.id] = timer
			timer:stop()
			timer:start(
				500,
				0,
				vim.schedule_wrap(function()
					if vim.lsp.get_client_by_id(client.id) then
						vim.lsp.diagnostic.on_refresh(
							nil,
							nil,
							{ client_id = client.id, method = "workspace/diagnostic/refresh" }
						)
					end
				end)
			)
		end,
	})
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		vim.b[buf].lsp_buffer_setup_done = nil
		vim.b[buf].lsp_organize_imports_set = nil
		for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
			on_attach({ buf = buf, data = { client_id = client.id } })
		end
	end
end

return M
