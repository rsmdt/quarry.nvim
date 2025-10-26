local M = {}

---Check if NeoVim supports native LSP configuration API (0.11+)
---@return boolean True if vim.lsp.config and vim.lsp.enable are available
function M.has_native_lsp_api()
	return vim.lsp.config ~= nil and vim.lsp.enable ~= nil
end

---Check if lspconfig is available
---@return boolean True if lspconfig can be loaded
function M.has_lspconfig()
	local ok, _ = pcall(require, "lspconfig")
	return ok
end

---Get the preferred LSP configuration method
---@return "native"|"lspconfig"|"none"
function M.get_lsp_config_method()
	if M.has_native_lsp_api() then
		return "native"
	elseif M.has_lspconfig() then
		return "lspconfig"
	else
		return "none"
	end
end

---Get information about the current LSP setup for debugging
---@return table<string, any>
function M.get_debug_info()
	return {
		has_native_api = M.has_native_lsp_api(),
		has_lspconfig = M.has_lspconfig(),
		config_method = M.get_lsp_config_method(),
		nvim_version = vim.version(),
	}
end

return M
