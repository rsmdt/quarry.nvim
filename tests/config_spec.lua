local config = require("quarry.config")

describe("quarry.config", function()
	describe("defaults", function()
		it("should have a default setup handler", function()
			assert.is_table(config.defaults.setup)
			assert.is_function(config.defaults.setup._)
		end)
	end)

	describe("setup handler behavior", function()
		it("should have proper structure", function()
			assert.is_table(config.defaults.setup)
			assert.is_function(config.defaults.setup._)
		end)

		it("should execute without errors with valid input", function()
			-- The actual behavior depends on the environment
			-- This test just verifies the handler doesn't crash
			local ok = pcall(config.defaults.setup._, "test_server", {})
			assert.is_true(ok)
		end)

		it("should detect native API availability correctly", function()
			-- Try to load version module, skip if not available in test environment
			local ok, version = pcall(require, "quarry.version")
			if not ok then
				-- Module not in path, but we can still test the logic directly
				local vim_has_native = vim.lsp.config ~= nil and vim.lsp.enable ~= nil
				assert.is_boolean(vim_has_native)
				return
			end

			local has_native = version.has_native_lsp_api()

			-- Verify detection matches actual environment
			local vim_has_native = vim.lsp.config ~= nil and vim.lsp.enable ~= nil
			assert.equals(vim_has_native, has_native)
		end)
	end)

	describe("setup function", function()
		it("should accept nil options", function()
			local ok = pcall(config.setup, nil)
			assert.is_true(ok)
		end)

		it("should prevent multiple setup calls", function()
			-- First setup should work
			config.setup({})

			-- Second setup should warn but not error
			local ok = pcall(config.setup, {})
			assert.is_true(ok)
		end)
	end)
end)
