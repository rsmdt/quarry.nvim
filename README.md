# quarry.nvim

![LuaRocks](https://img.shields.io/luarocks/v/rudionrails/quarry.nvim?style=for-the-badge)

**quarry.nvim** is a plugin to simplify the setup of LSP and other tools for your **Neovim** configuration. It build on top of Mason to orchestrate lsp setup and tools (DAP, formatter, linter) installation.

## ✨ Features

- Passes `vim.lsp.protocol.make_client_capabilities()` as default capabilities to any LSP
- Configure `ensure_installed` to install all available tools in mason, via mason-lspconfig

## ⚡️Requirements

- [`Neovim`](https://neovim.io/) >= 0.10.0
- [`williamboman/mason.nvim`](https://github.com/williamboman/mason.nvim)
- [`williamboman/mason-lspconfig.nvim`](https://github.com/williamboman/mason-lspconfig.nvim)
- [`neovim/nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig)

## 📦 Installation

> [!NOTE]
> By default, this plugin only sets up the standard lsp capabilities for generic LSP. You need to read the Configuration section for more sophisticated setup.

### With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    {
        "rudionrails/quarry.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig"
        },

    }
}

```

## ⚙️ Configuration

**quarry.nvim** comes with the following defaults:

```lua
require("quarry").setup({
    -- capabilities can also be defined as Lua table, ex. `capabilities = {}`
	capabilities = function()
		return vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities())
	end,

    -- Provide globally required mason tools; will be installed upon `require("quarry").setup()`
	ensure_installed = {},

    -- Provide specific LSP here. A default server handler will be defined in any case.
	servers = {},
})
```

## 🚀 Additional Configuration Examples

### Configure generic LSP `on_attach` and `capabilities` (see `:h lspconfig-configurations`)

```lua
require("quarry").setup({
    ---
    -- will be passed to every LSP. Alternatively, use `LspAttach` event.
    on_attach = function(client, bufnr)
        -- selectively add keymaps
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Show LSP hover" })

        -- selectively enable inlayHint for attached client
        if client.supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,

    ---
    -- will be passed to every LSP.
    -- NOTE: for the below example, make sure `cmp-nvim-lsp` is available
    capabilities = function()
        local cmp_nvim_lsp = require("hrsh7th/cmp-nvim-lsp")

        return vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_nvim_lsp.default_capabilities()
        )
    end,
})

```

### Configure language servers (LSP)

```lua
---
-- quarry.nvim uses mason-lspconfig under the hood to setup LSP and other tools. The settings passed for
-- each server look similar but are slightly adjusted to allow for easier composition.
require("quarry").setup({
	servers = {
        -- use the LSP name as a key (like you would for mason-lspconfig)
        lua_ls = {
            ---
            -- Tools are installed only when opening such filetypes (lazily), otherwise thy are installed
            -- upon `require("quarry").setup()`. The `filetypes` key is optional and unrelated to the 
            -- filetypes option in the lspconfig package.
            ---@type string[]
            filetypes = { "lua" },

            ---
            -- Provide the tools to install. This allows for all available mason tools, not just LSP.
            -- You can omit `lua_ls` in the below example, as it will be installed automatically. It is
            -- taken for any LSP from the server key of the table.
            ---@type string[]
            ensure_installed = { "lua_ls", "stylua", "luacheck" },

            ---
            -- Pass the opts for the language server as you would with mason-lspconfig
            ---@type table<any, any>
            opts = {
                settings = {
                    Lua = {
                        completion = { callSnippet = "Replace" },
                        doc = { privateName = { "^_" } },
                        codeLens = { enable = true },
                        hint = { enable = true },
                        workspace = { checkThirdParty = false },
                    },

                    -- Do not send telemetry data containing a randomized but unique identifier
                    telemetry = { enable = false },
                },
            },

            ---
            -- Provide a custom setup function. When defined, this will override the default
            -- provided by quarry.nvim for this LSP. The function takes 2 arguments: the name of
            -- the lsp, ex. lua_ls, rust_analyzer, and the configuration defined in the `opts` table.
            ---@type fun(name: string, opts: table<any any>)
            setup = function(name, opts)
                require("lspconfig")[name].setup(opts)
            end,
        },

        ---
        -- Other LSP will follow the same pattern, ex.
        -- rust_analyzer = { ... }
    },
})
```

### Composable configuration for many LSP (requires [lazy.nvim](https://github.com/folke/lazy.nvim))

When you use many LSP, your configuration table may become quite large. You can take advantage of a lazy.nvim behaviour and separate the LSP into different files. lazy.nvim merges the `opts` in case a plugin is defined multiple times.

> [!TIP]
> You can tweak the below example however you like. I found it most simple for the majority of purposes.


1. Setup lazy.nvim and provide an additional `extras` spec.

```lua
-- file: lua/init.lua

-- ... require lazy.nvim as you usually would. Check out the documentation for detailed instructions ...
require("lazy").setup({
	{ import = "plugins" },
	{ import = "extras" }, -- <- this is the relevant line
}, {
    -- .. regular lazy.nvim configuration ...
})
```

2. Setup **quarry.nvim** inside the `plugins` directory, alongside your other lazy.nvim plugins.

```lua
-- file: lua/plugins/quarry.lua
return {
    "rudionrails/quarry.nvim",
    event = "VeryLazy",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",

        -- not required by quarry.nvim
        "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
        on_attach = function(client, bufnr)
            -- Enable completion triggered by <c-x><c-o>
            vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

            -- helper function for keymaps on current buffer
            local nmap = function(lhs, rhs, desc)
                vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
            end

            nmap("[d", vim.diagnostic.goto_prev)
            nmap("]d", vim.diagnostic.goto_next)
            nmap("K", vim.lsp.buf.hover, "Show lsp hover")
            nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
            nmap("gs", vim.lsp.buf.signature_help, "[G]oto [s]ignature")
            nmap("gd", vim.lsp.buf.definition, "[G]oto [d]efinition")
            nmap("gr", vim.lsp.buf.references, "[G]oto [r]eferences")
            nmap("gi", vim.lsp.buf.implementation, "[G]oto [i]mplementation")
            nmap("gt", vim.lsp.buf.type_definition, "[G]oto [t]ype definition")

            nmap("<leader>a", vim.lsp.buf.code_action, "Code [a]ction")
            nmap("<leader>r", vim.lsp.buf.rename, "[R]ename word under cursor within project")
            nmap("<leader>h", function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            end, "Toggle inlay [h]int")
        end,

        capabilities = function()
            local cmp_nvim_lsp = require("hrsh7th/cmp-nvim-lsp")

            return vim.tbl_deep_extend(
                "force",
                {},
                vim.lsp.protocol.make_client_capabilities(),
                cmp_nvim_lsp.default_capabilities()
            )
        end,
    },
}

```

3. Setup LSP inside `extras` directory.

```lua
-- file: lua/extras/lua.lua

return {
	"rudionrails/quarry.nvim",
	opts = {
		servers = {
			lua_ls = {
				filetypes = { "lua" },
				ensure_installed = {
					"lua_ls",
					"stylua",
					"luacheck",
				},
				opts = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							doc = { privateName = { "^_" } },
							codeLens = { enable = true },
							hint = {
								enable = true,
								setType = false,
								paramType = true,
								paramName = "Disable",
								semicolon = "Disable",
								arrayIndex = "Disable",
							},
							workspace = {
								checkThirdParty = false,
							},
						},

						-- Do not send telemetry data containing a randomized but unique identifier
						telemetry = { enable = false },
					},
				},
			},
		},
	},
}

```

```lua
-- file: lua/extras/tsserver.lua

return {
	"rudionrails/quarry.nvim",
	opts = {
		servers = {
			tsserver = {
				filetypes = {
                    "javascript",
                    "javascriptreact",
                    "javascript.jsx",
                    "typescript",
                    "typescriptreact",
                    "typescript.tsx",
				},

				ensure_installed = {
					"tsserver",
					"prettier", -- prettierd as alternative
					"eslint", -- eslint_d as alternative
				},

				opts = {
					completions = {
						completeFunctionCalls = true,
					},
					init_options = {
						preferences = {
							includeInlayParameterNameHints = "all", -- 'none' | 'literals' | 'all';
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
							importModuleSpecifierPreference = "non-relative",
						},
					},
				},
			},
		},
	},
}

```


## Development

- use [`conventional-commits`](https://www.conventionalcommits.org/) as commit message to enable automatic versioning
- refer to [`neorocks`](https://github.com/nvim-neorocks/sample-luarocks-plugin) to see how publishing to [luarocks](https://luarocks.org/) works
