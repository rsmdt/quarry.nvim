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
	-- Default setup function supports both NeoVim 0.11+ native API and legacy lspconfig.
	-- Automatically detects and uses the appropriate method.
	---@type table<string, fun(nane: string, opts: table<any, any>)>
	setup = {
		_ = function(name, opts)
			-- NeoVim 0.11+ native API support
			if vim.lsp.config and vim.lsp.enable then
				-- Use native LSP configuration API
				vim.lsp.config(name, opts)
				vim.lsp.enable(name)
				return
			end

			-- Fallback to legacy lspconfig for NeoVim 0.10 or when explicitly using lspconfig
			local ok, lspconfig = pcall(require, "lspconfig")
			if ok then
				lspconfig[name].setup(opts)
			else
				-- Neither native API nor lspconfig available
				u.notify(
					string.format(
						'Unable to setup "%s": NeoVim 0.11+ native API not available and lspconfig not found',
						name
					),
					vim.log.levels.ERROR
				)
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

	local _capabilities
	local capabilities = function()
		if _capabilities == nil then
			_capabilities = type(config.capabilities) == "function" and config.capabilities() or config.capabilities
		end
		return _capabilities
	end

	local on_attach = function(client, bufnr)
		require("quarry.features").setup(client, bufnr, config.features)
		require("quarry.keymaps").setup(client, bufnr, config.keys)

		config.on_attach(client, bufnr)
	end

	local register_servers = function()
		-- apply capabilities and on_attach to every server, including those
		-- installed via Mason but not configured through `servers`
		if vim.lsp.config and vim.lsp.enable then
			vim.lsp.config("*", {
				capabilities = capabilities(),
				on_attach = on_attach,
			})
		end

		for name, _server in pairs(config.servers) do
			local setup = config.setup[name] or config.setup["_"]
			local server = vim.tbl_deep_extend("force", {}, u._server_defaults, _server)

			local server_config = vim.tbl_deep_extend("force", {
				capabilities = capabilities(),
				on_attach = on_attach,
			}, server.config or {})

			setup(name, server_config)
		end

		-- `automatic_enable` picks up servers that are installed but not
		-- configured through `servers`
		local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
		if ok and type(mason_lspconfig.setup) == "function" then
			mason_lspconfig.setup({})
		end
	end

	-- defer the heavy work off the startup path; `vim.lsp.enable` attaches to
	-- already-open buffers, so late registration is safe
	vim.schedule(function()
		register_servers()
		require("quarry.installer").setup(config)
	end)
end

return M
