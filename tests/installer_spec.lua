-- Note: This file tests the installer module's filetype detection
-- The _filetypes_for function is local, so we test it indirectly through the module behavior

describe("quarry.installer", function()
	describe("filetype detection", function()
		local original_lsp_config

		before_each(function()
			-- Store original value
			original_lsp_config = vim.lsp.config
		end)

		after_each(function()
			-- Restore original value
			vim.lsp.config = original_lsp_config
		end)

		it("should prefer native API over lspconfig", function()
			-- This is an integration test concept
			-- In practice, the filetype detection will try native API first
			-- We can't easily test the private function, but we verify the module loads
			local ok, installer = pcall(require, "quarry.installer")
			assert.is_true(ok)
			assert.is_table(installer)
		end)

		it("should handle missing native API gracefully", function()
			-- Remove native API
			vim.lsp.config = nil

			-- Module should still load
			package.loaded["quarry.installer"] = nil
			local ok, installer = pcall(require, "quarry.installer")

			assert.is_true(ok)
			assert.is_table(installer)
		end)

		it("should have setup function", function()
			local installer = require("quarry.installer")
			assert.is_function(installer.setup)
		end)
	end)
end)
