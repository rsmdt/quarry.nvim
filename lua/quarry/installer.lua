local u = require("quarry.utils")

local M = {}

-- keep track of what was aready installed
local _installed_by_quarry = {}

local _mappings
local _lspconfig_to_mason = function(name)
	if _mappings == nil then
		local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
		local has_mappings, mappings = false, nil

		if ok then
			has_mappings, mappings = pcall(mason_lspconfig.get_mappings)
		end

		if has_mappings and type(mappings) == "table" then
			-- mason-lspconfig renamed `lspconfig_to_mason` to `lspconfig_to_package`
			_mappings = mappings.lspconfig_to_package or mappings.lspconfig_to_mason or {}
		else
			_mappings = {}
		end
	end

	return _mappings[name] or name
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

local _listeners_registered = false
local _register_listeners = function(mason_registry)
	if _listeners_registered then
		return
	end

	_listeners_registered = true
	mason_registry:on("package:install:success", _on_success)
	mason_registry:on("package:install:failed", _on_failed)
end

---@param tools string[]
local _install = function(tools)
	local has_registry, mason_registry = pcall(require, "mason-registry")
	if not has_registry then
		u.notify("mason.nvim not found, tools will not be installed.", vim.log.levels.WARN)
		return
	end

	for _, tool in ipairs(tools) do
		local name = _lspconfig_to_mason(tool)
		local has_package, p = pcall(mason_registry.get_package, name)

		if not has_package then
			u.notify(string.format('"%s" not found in Mason registry.', name), vim.log.levels.WARN)
		elseif not p:is_installed() then
			_register_listeners(mason_registry)
			_installed_by_quarry[p.name] = true
			p:install()
		end
	end
end

---@param name: string
local _filetypes_for = function(name)
	if vim.lsp.config then
		local ok, lsp_config = pcall(function()
			return vim.lsp.config[name]
		end)

		if ok and type(lsp_config) == "table" and type(lsp_config.filetypes) == "table" then
			return lsp_config.filetypes
		end
	end

	local ok, config = pcall(require, "lspconfig.configs." .. name)
	if ok and type(config.default_config) == "table" then
		return config.default_config.filetypes or {}
	end

	return {}
end

---
-- Install the provided tools via mason, mason-lspconfig
--
---@param config quarry.Config The configuration
function M.setup(config)
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
