local mason_lspconfig = require("mason-lspconfig")
local mason_registry = require("mason-registry")

local u = require("quarry.utils")

local M = {}

-- keep track of what was aready installed
local _installed_by_quarry = {}

---@param tools string[]
local _install = function(tools)
	for _, tool in ipairs(tools) do
		do
			if tool == nil then
				break
			end

			local name = mason_lspconfig.get_mappings().lspconfig_to_mason[tool] or tool
			local has_package, p = pcall(mason_registry.get_package, name)

			if not has_package then
				u.notify(string.format('"%s" not found in Mason registry.', name), vim.log.levels.WARN)
				break
			end

			if not p:is_installed() then
				_installed_by_quarry[p.name] = true
				p:install()
			end
		end
	end
end

---Get filetypes for a language server
---Tries native vim.lsp.config first (NeoVim 0.11+), then falls back to lspconfig
---@param name string The language server name
---@return string[] Array of filetypes
local _filetypes_for = function(name)
	-- Strategy 1: Try native NeoVim 0.11+ API
	if vim.lsp.config and type(vim.lsp.config[name]) == "table" then
		local native_config = vim.lsp.config[name]
		if native_config.filetypes and #native_config.filetypes > 0 then
			return native_config.filetypes
		end
	end

	-- Strategy 2: Try lspconfig module
	local ok, config = pcall(require, "lspconfig.configs." .. name)
	if ok and type(config.default_config) == "table" then
		local filetypes = config.default_config.filetypes or {}
		if #filetypes > 0 then
			return filetypes
		end
	end

	-- Strategy 3: Return empty array (safe fallback)
	return {}
end

---@param p: Package
local _on_success = function(p)
	if not _installed_by_quarry[p.name] then
		return
	end

	_installed_by_quarry[p.name] = false

	-- trigger FileType event to possibly load the newly installed tools
	vim.defer_fn(function()
		vim.api.nvim_exec_autocmds("FileType", { buffer = vim.api.nvim_get_current_buf() })
	end, 100)
end

---@param p: Package
local _on_failed = function(p)
	if not _installed_by_quarry[p.name] then
		return
	end

	_installed_by_quarry[p.name] = false
	u.notify(string.format('"%s" could not be installed. Check :MasonLog for details.', p.name), vim.log.levels.ERROR)
end

---
-- Install the provided tools via mason, mason-lspconfig
--
---@param config quarry.Config The configuration
function M.setup(config)
	mason_registry:on("package:install:success", _on_success)
	mason_registry:on("package:install:failed", _on_failed)

	local tools = vim.list_extend({}, config.tools)

	-- install general defined tools now
	if #tools > 0 then
		_install(tools)
	end

	-- install tools per defined server
	for name, _server in pairs(config.servers) do
		local server = vim.tbl_deep_extend("force", {}, u._server_defaults, _server)
		local server_filetypes = #server.filetypes > 0 and server.filetypes or _filetypes_for(name)
		local server_tools = u.tbl_filter_numeric_keys(server.tools)

		if server.tools.lazy then
			-- install when associated filetype is recognized (lazy)
			local group = vim.api.nvim_create_augroup("quarry_install_" .. name, { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = server_filetypes,
				callback = function()
					vim.api.nvim_del_augroup_by_id(group)
					_install(server_tools)
				end,
			})
		else
			-- install now
			_install(server_tools)
		end
	end
end

return M
