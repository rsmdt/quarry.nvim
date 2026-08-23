local M = {}

---
-- Features are what the LSP client is able to support via `client.supports_method()`
--
-- Enable selected features with their default configuration
--   quarry.setup({
--     features = {
--       -- uses the default function from quarry.nvim
--       "textDocument/documentHighlight",
--
--       -- pass a table with `cond` and `setup` function
--       ["textDocument/inlayHint"] = {
--         cond = "textDocument/inlayHint" -- this is used as default and taken from key
--         setup = function(client, bufnr) -- only executes when `cond` is satisied
--
--         end,
--       },
--
--        -- no magic applied, all logic is with you
--       ["textDocument/codeLens"] = function(client, bufnr)
--       end,
--     }
--   })
--
-- @type table<string, quarry.Feature>|string
M._features = {
	---
	-- Highlight on current word
	["textDocument/documentHighlight"] = function(_, bufnr)
		local group = vim.api.nvim_create_augroup("quarry_textDocument/documentHighlight", { clear = false })

		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.document_highlight()
			end,
		})

		-- Remove highlight on current word
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.clear_references()
			end,
		})

		return function()
			vim.lsp.buf.clear_references()
			vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
		end
	end,

	---
	-- Inlay hints
	["textDocument/inlayHint"] = function(_, bufnr)
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end,

	---
	-- Code lens
	["textDocument/codeLens"] = function(_, bufnr)
		local group = vim.api.nvim_create_augroup("quarry_textDocument/codeLens", { clear = false })

		vim.lsp.codelens.refresh()
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.lsp.codelens.refresh()
			end,
		})

		return function()
			vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
		end
	end,
}

---@private
function M._supports_method(client, method)
	if vim.fn.has("nvim-0.11") == 1 then
		return client:supports_method(method)
	end

	return client.supports_method(method)
end

---@private
function M._format(features)
	local _features = {}

	for feature, config in pairs(features) do
		if type(feature) == "number" and type(config) == "string" and M._features[config] then
			table.insert(_features, { feature = config, cond = config, setup = M._features[config] })
		elseif type(feature) == "string" and type(config) == "function" then
			table.insert(_features, { feature = feature, cond = feature, setup = config })
		elseif type(feature) == "string" and type(config) == "table" and type(config.setup) == "function" then
			table.insert(_features, { feature = feature, cond = config.cond or feature, setup = config.setup })
		end
	end

	return _features
end

---
-- Setup LSP client features for the provided buffer
--
---@param client vim.lsp.Client
---@param bufnr number
---@param features table<string, fun()>
function M.setup(client, bufnr, features)
	local _features = M._format(features)
	local _teardowns = {}

	for _, config in ipairs(_features) do
		if
			type(config.cond) == "boolean" and config.cond
			or type(config.cond) == "string" and M._supports_method(client, config.cond)
			or type(config.cond) == "function" and config.cond(client, bufnr)
		then
			local teardown = config.setup(client, bufnr)

			if type(teardown) == "function" then
				table.insert(_teardowns, teardown)
			end
		end
	end

	if #_teardowns ~= 0 then
		vim.api.nvim_create_autocmd("LspDetach", {
			buffer = bufnr,
			callback = function(event)
				if event.data.client_id ~= client.id or event.buf ~= bufnr then
					return
				end

				for _, teardown in ipairs(_teardowns) do
					teardown(client, bufnr)
				end
			end,
		})
	end
end

return M
