local mason_lspconfig = require("mason-lspconfig")

local installer = require("quarry.installer")
local u = require("quarry.utils")

local M = {}

local _is_setup = false

---@class quarry.Config
M.defaults = {
	---
	-- List of global tools to install
	---@type string[]
	tools = {},

	---
	-- Enable LSP features for attached client
	features = {},

	---
	-- Pass keymaps for attached client
	---@type table<string, quarry.Keymap>
	keys = {},

	---
	-- Global capabilities that are passed to every LSP
	---@type lsp.ClientCapabilities|fun():lsp.ClientCapabilities
	capabilities = vim.lsp.protocol.make_client_capabilities,

	---
	-- Global on_attach that is passed to every LSP
	---@type fun(client: vim.lsp.Client, bufnr: integer)
	on_attach = function(client, bufnr) end,

	---
	-- Configure every LSP individually. Ideal to separate into multiple files.
	---@type table<string, quarry.Server>
	servers = {},

	---
	-- Default setup function assumes lspconfig, but will gracefully do nothing if not available,
	-- so that you can override with your custom implementation.
	---@type table<string, fun(nane: string, opts: table<any, any>)>
	setup = {
		_ = function(name, opts)
			local ok, lspconfig = pcall(require, "lspconfig")

			if ok then
				lspconfig[name].setup(opts)
			end
		end,
	},
}

--- Setup the plugin
---@param opts? quarry.Config
function M.setup(opts)
	if _is_setup then
		u.notify("setup() already called", vim.log.levels.WARN)
		return
	else
		_is_setup = true
	end

	local config = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
	local capabilities = type(config.capabilities) == "function" and config.capabilities() or config.capabilities
	local on_attach = function(client, bufnr)
		require("quarry.features").setup(client, bufnr, config.features)
		require("quarry.keymaps").setup(client, bufnr, config.keys)

		config.on_attach(client, bufnr)
	end

	-- setup servers from `servers` option
	mason_lspconfig.setup({
		handlers = {
			function(name)
				local setup = config.setup[name] or config.setup["_"]
				local server = vim.tbl_deep_extend("force", {}, u._server_defaults, config.servers[name] or {})

				local server_config = vim.tbl_deep_extend("force", {
					capabilities = capabilities,
					on_attach = on_attach,
				}, server.config or {})

				setup(name, server_config)
			end,
		},
	})

	-- install tools
	installer.setup(config)
end

return M
