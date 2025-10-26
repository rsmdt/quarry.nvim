local version = require("quarry.version")

describe("quarry.version", function()
	describe("has_native_lsp_api", function()
		it("should return a boolean", function()
			local has_native = version.has_native_lsp_api()
			assert.is_boolean(has_native)
		end)

		it("should detect vim.lsp.config existence", function()
			local has_native = version.has_native_lsp_api()
			local expected = vim.lsp.config ~= nil and vim.lsp.enable ~= nil

			assert.equals(expected, has_native)
		end)
	end)

	describe("has_lspconfig", function()
		it("should return a boolean", function()
			local has_lspconfig = version.has_lspconfig()
			assert.is_boolean(has_lspconfig)
		end)

		it("should detect lspconfig availability", function()
			local has_lspconfig = version.has_lspconfig()
			local ok, _ = pcall(require, "lspconfig")

			assert.equals(ok, has_lspconfig)
		end)
	end)

	describe("get_lsp_config_method", function()
		it("should return one of the valid methods", function()
			local method = version.get_lsp_config_method()
			local valid_methods = {
				native = true,
				lspconfig = true,
				none = true,
			}

			assert.is_true(valid_methods[method])
		end)

		it("should prefer native over lspconfig when both available", function()
			local has_native = version.has_native_lsp_api()
			local method = version.get_lsp_config_method()

			if has_native then
				assert.equals("native", method)
			end
		end)

		it("should return lspconfig when native not available but lspconfig is", function()
			local has_native = version.has_native_lsp_api()
			local has_lspconfig = version.has_lspconfig()
			local method = version.get_lsp_config_method()

			if not has_native and has_lspconfig then
				assert.equals("lspconfig", method)
			end
		end)

		it("should return none when neither available", function()
			local has_native = version.has_native_lsp_api()
			local has_lspconfig = version.has_lspconfig()
			local method = version.get_lsp_config_method()

			if not has_native and not has_lspconfig then
				assert.equals("none", method)
			end
		end)
	end)

	describe("get_debug_info", function()
		it("should return a table", function()
			local info = version.get_debug_info()
			assert.is_table(info)
		end)

		it("should contain expected fields", function()
			local info = version.get_debug_info()

			assert.is_not_nil(info.has_native_api)
			assert.is_not_nil(info.has_lspconfig)
			assert.is_not_nil(info.config_method)
			assert.is_not_nil(info.nvim_version)
		end)

		it("should have boolean values for capability checks", function()
			local info = version.get_debug_info()

			assert.is_boolean(info.has_native_api)
			assert.is_boolean(info.has_lspconfig)
		end)

		it("should have valid config_method", function()
			local info = version.get_debug_info()
			local valid_methods = {
				native = true,
				lspconfig = true,
				none = true,
			}

			assert.is_true(valid_methods[info.config_method])
		end)
	end)
end)
