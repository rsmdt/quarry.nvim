# quarry.nvim

[![LuaRocks](https://img.shields.io/luarocks/v/rudionrails/quarry.nvim?style=for-the-badge)](https://luarocks.org/modules/rudionrails/quarry.nvim)

**quarry.nvim** is a wrapper for mason, mason-lspconfig, and lspconfig to orgnize LSP setup for **Neovim**.

## ✨ Rationale

Having multiple LSP can easily bloat your single-file configuration. You still want to manage LSP yourself so you still understand what is going on. So you need a simple way to split your setup into multiple files.

### What quarry.nvim will do for you

- Composable LSP configuration that is split into multiple files (best with lazy.nvim)
- Lazily install LSP the first time you open a relevant file to keep your Neovim startup blazingly fast
- Install additional tools without fuzz, ex. DAP, linter, formatter (⚠️ configuration of those is still with you)
- Configures minimal LSP capabilities and server setup, which can all be overwritten if needed

### What will quarry.nvim not do for you

- it is not a swiss army knife solution with with a one-line setup to automagically manage all your Neovim LSP, DAP, formatter, and linter needs.

> [!IMPORTANT]
>  If you are not interested in managing your own configuration, then you better head over to [none-ls](https://github.com/nvimtools/none-ls.nvim) or [lsp-zero](https://github.com/VonHeikemen/lsp-zero.nvim).

## ⚡️Requirements

- [`Neovim`](https://neovim.io/) >= 0.10.0
- [`williamboman/mason.nvim`](https://github.com/williamboman/mason.nvim)
- [`williamboman/mason-lspconfig.nvim`](https://github.com/williamboman/mason-lspconfig.nvim)
- [`neovim/nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig)

## 📦 Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    {
        "rudionrails/quarry.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",

            -- the default server config assumes that you use lspconfig. If this is not the case,
            -- you can omit this and override with your own implementaiotn (see below examples).
            -- quarry.nvim will gracefully handle if lspconfig is not available.
            "neovim/nvim-lspconfig"
        },
    }
}

```

## ⚙️ Configuration

> [!NOTE]
> The below shows the default configuration and you do not need to provide this explicitly.

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

    -- Provide LSP-specific setup functions or override the default.
    setup = {
        _ = function(name, opts) -- <- this is the default, BTW
            local ok, lspconfig = pcall(require, "lspconfig")
            if ok then
                lspconfig[name].setup(opts)
            end
        end
    }
})
```

## 🚀 Composable configuration (best enjoyed with [lazy.nvim](https://github.com/folke/lazy.nvim))

When you use many LSP, your configuration table may become quite large. You can take advantage of a lazy.nvim behaviour and separate the LSP into different files. lazy.nvim merges the `opts` in case a plugin is defined multiple times.

> [!TIP]
> `on_attach` and `capabilities` are optional. For details see `:h lspconfig-configurations` inside Neovim. Both settings are totally optional.

> [!NOTE]
> You can tweak the below example however you like. I found it most simple for the majority of purposes.

inside your Neovim configuration directory, you will have:

- `lua/plugins/lsp.lua` as your base setup
- `lua/extras/lua.lua` for [Lua LSP](https://github.com/LuaLS/lua-language-server) specific configuration
- `lua/extras/typescript.lua` for [Typescript LSP](https://github.com/typescript-language-server/typescript-language-server) specific configuration
- ...extend with other LSP as you like

<details>
<summary>Setup lazy.nvim and provide additional extras spec</summary>

```lua
-- file: lua/init.lua

-- ... require lazy.nvim as you usually would. Check out the documentation for detailed instructions ...
require("lazy").setup({
    { import = "plugins" },
    { import = "extras" }, -- <- this is the relevant line, BTW
}, {
    -- .. regular lazy.nvim configuration ...
})
```
</details>

<details>
<summary>Setup **quarry.nvim** in `lua/plugins/lsp.lua`</summary>

```lua
-- file: lua/plugins/quarry.lua
return {
    "rudionrails/quarry.nvim",
    event = "VeryLazy",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",

        -- not required by quarry.nvim, just to show how to extend capabilities
        "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
        ---
        -- will be passed to every LSP. Alternatively, use `LspAttach` event.
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

        ---
        -- will be passed to every LSP.
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
</details>

<details>
<summary>Setup lua-language-server in `lua/extras/lua.lua`</summary>

```lua
-- file: lua/extras/lua.lua
return {
    "rudionrails/quarry.nvim",
    opts = {
        servers = {
            lua_ls = {
                filetypes = { "lua" },
                ensure_installed = {
                    -- "lua_ls" itself will be automatically installed, since it is the key of the LSP
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
</details>


<details>
<summary>Setup typescript-language-server in `lua/extras/typescript.lua`</summary>

```lua
-- file: lua/extras/typescript.lua
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
                    -- "tsserver" itself will be automatically installed, since it is the key of the LSP
                    "prettier", -- prettierd as alternative
                    "eslint", -- eslint_d as alternative
                },

                opts = {
                    completions = { completeFunctionCalls = true },
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
</details>

## Similar projects

- [`astrolsp`](https://github.com/AstroNvim/astrolsp)
- [`lsp-setup`](https://github.com/junnplus/lsp-setup.nvim)

## Development

- use [`conventional-commits`](https://www.conventionalcommits.org/) as commit message to enable automatic versioning
- refer to [`neorocks`](https://github.com/nvim-neorocks/sample-luarocks-plugin) to see how publishing to [luarocks](https://luarocks.org/) works
