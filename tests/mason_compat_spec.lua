-- Mason v1/v2 compatibility + installer regression tests.
--
-- `mason-lspconfig` and `mason-registry` are not available in the test
-- environment, so we inject fakes into `package.loaded` before requiring the
-- quarry modules (their top-level locals capture them at require time). This
-- lets us drive both the mason-lspconfig v1 and v2 code paths deterministically.

local function fake_package(name, is_installed)
	return {
		name = name,
		is_installed = function()
			return is_installed
		end,
	}
end

describe("installer tool installation", function()
	local installer
	local install_calls -- package names passed to Package:install()
	local present -- table<name, fake package> the fake registry knows about

	local function pkg(name, is_installed)
		local p = fake_package(name, is_installed)
		p.install = function()
			table.insert(install_calls, name)
		end
		return p
	end

	local function set_mappings(map)
		package.loaded["mason-lspconfig"] = {
			get_mappings = function()
				return map
			end,
		}
		package.loaded["quarry.installer"] = nil
		installer = require("quarry.installer")
	end

	before_each(function()
		install_calls = {}
		present = {}

		package.loaded["mason-registry"] = {
			on = function(_, _, _) end,
			get_package = function(name)
				local p = present[name]
				if not p then
					error(string.format("package %q not found", name))
				end
				return p
			end,
		}

		-- default: v2-style mapping, identity
		set_mappings({ lspconfig_to_package = {} })
	end)

	after_each(function()
		package.loaded["mason-lspconfig"] = nil
		package.loaded["mason-registry"] = nil
		package.loaded["quarry.installer"] = nil
	end)

	it("installs an uninstalled tool", function()
		present["lua_ls"] = pkg("lua_ls", false)

		installer.setup({ tools = { "lua_ls" }, servers = {} })

		assert.are.same({ "lua_ls" }, install_calls)
	end)

	it("does not reinstall an already-installed tool", function()
		present["stylua"] = pkg("stylua", true)

		installer.setup({ tools = { "stylua" }, servers = {} })

		assert.are.same({}, install_calls)
	end)

	-- Regression: a tool missing from the registry must NOT abort installation
	-- of the remaining tools (was a `break` inside the loop).
	it("keeps installing remaining tools when one is missing", function()
		present["found_a"] = pkg("found_a", false)
		present["found_b"] = pkg("found_b", false)
		-- "MISSING" is intentionally absent

		installer.setup({ tools = { "found_a", "MISSING", "found_b" }, servers = {} })

		assert.are.same({ "found_a", "found_b" }, install_calls)
	end)

	-- mason-lspconfig v2 renamed the mapping key.
	it("resolves names via the v2 lspconfig_to_package mapping", function()
		set_mappings({ lspconfig_to_package = { ts_ls = "typescript-language-server" } })
		present["typescript-language-server"] = pkg("typescript-language-server", false)

		installer.setup({ tools = { "ts_ls" }, servers = {} })

		assert.are.same({ "typescript-language-server" }, install_calls)
	end)

	-- mason-lspconfig v1 used a different key; the fallback keeps it working.
	it("resolves names via the v1 lspconfig_to_mason mapping", function()
		set_mappings({ lspconfig_to_mason = { ts_ls = "typescript-language-server" } })
		present["typescript-language-server"] = pkg("typescript-language-server", false)

		installer.setup({ tools = { "ts_ls" }, servers = {} })

		assert.are.same({ "typescript-language-server" }, install_calls)
	end)
end)

describe("config mason-lspconfig version handling", function()
	local configured -- name -> server_config captured from the setup handler
	local mlsp_setup_opts -- opts passed to mason_lspconfig.setup()

	local function load_config(mason_lspconfig)
		package.loaded["mason-lspconfig"] = mason_lspconfig
		package.loaded["mason-registry"] = {
			on = function(_, _, _) end,
			get_package = function(name)
				return fake_package(name, true) -- already installed: no install attempts
			end,
		}
		package.loaded["quarry.installer"] = nil
		package.loaded["quarry.config"] = nil
		return require("quarry.config")
	end

	-- capture configured servers instead of touching vim.lsp
	local function opts_with_capture(extra)
		return vim.tbl_deep_extend("force", {
			servers = {},
			tools = {},
			setup = {
				_ = function(name, server_config)
					configured[name] = server_config
				end,
			},
		}, extra or {})
	end

	before_each(function()
		configured = {}
		mlsp_setup_opts = nil
	end)

	after_each(function()
		package.loaded["mason-lspconfig"] = nil
		package.loaded["mason-registry"] = nil
		package.loaded["quarry.config"] = nil
		package.loaded["quarry.installer"] = nil
	end)

	it("uses the handlers mechanism on mason-lspconfig v1", function()
		local handlers
		local config = load_config({
			setup_handlers = function(_) end, -- presence => v1
			setup = function(o)
				mlsp_setup_opts = o
				handlers = o.handlers
			end,
			get_mappings = function()
				return { lspconfig_to_mason = {} }
			end,
			get_installed_servers = function()
				return {}
			end,
		})

		config.setup(opts_with_capture())

		assert.is_table(handlers) -- v1 path passed handlers
		handlers[1]("lua_ls") -- simulate mason invoking the default handler
		assert.is_table(configured["lua_ls"])
		assert.is_truthy(configured["lua_ls"].capabilities)
	end)

	it("configures installed servers directly on mason-lspconfig v2", function()
		local config = load_config({
			-- no setup_handlers => v2
			setup = function(o)
				mlsp_setup_opts = o
			end,
			get_mappings = function()
				return { lspconfig_to_package = {} }
			end,
			get_installed_servers = function()
				return { "lua_ls", "ts_ls" }
			end,
		})

		config.setup(opts_with_capture())

		-- v2 path disables automatic_enable and configures installed servers itself
		assert.is_false(mlsp_setup_opts.automatic_enable)
		assert.is_table(configured["lua_ls"])
		assert.is_table(configured["ts_ls"])
		assert.is_truthy(configured["lua_ls"].capabilities)
	end)
end)
