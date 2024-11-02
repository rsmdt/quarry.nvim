<div align="center">
    <a href="https://github.com/rudionrails/quarry.nvim/releases/latest">
        <img alt="GitHub Release" src="https://img.shields.io/github/v/release/rudionrails/quarry.nvim?style=for-the-badge&logo=semver" />
    </a>
    <a href="https://luarocks.org/modules/rudionrails/quarry.nvim">
        <img alt="LuaRocks Package" src="https://img.shields.io/luarocks/v/rudionrails/quarry.nvim?style=for-the-badge&logo=lua" />
    <a/>
    <a href="https://github.com/rudionrails/quarry.nvim/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/rudionrails/quarry.nvim?style=for-the-badge&logo=apache" />
    </a>
</div>


**quarry.nvim** is a wrapper for mason, mason-lspconfig, and lspconfig to orgnize LSP setup for **Neovim**.

## ✨ Rationale

Having multiple LSP can easily bloat your single-file configuration. You still want to manage LSP yourself so you still understand what is going on. So you need a simple way to split your setup into multiple files.

### What quarry.nvim will do for you

- Composable LSP configuration
- Lazy LSP installation only when required to keep your Neovim blazingly fast
- Additional tool installation without fuzz, ex. DAP, linter, formatter (⚠️ configuration of those is still with you)
- Configures minimal LSP capabilities and server setup

### What will quarry.nvim not do for you

- it is not a swiss army knife solution with with a one-line setup to automagically manage all your Neovim LSP, DAP, formatter, and linter needs.

> [!IMPORTANT]
>  If you are not interested in managing your own configuration, then you better head over to [none-ls](https://github.com/nvimtools/none-ls.nvim) or [lsp-zero](https://github.com/VonHeikemen/lsp-zero.nvim).

## ⚡️Requirements

- [`Neovim`](https://neovim.io/) >= 0.10.0
- [`williamboman/mason.nvim`](https://github.com/williamboman/mason.nvim)
- [`williamboman/mason-lspconfig.nvim`](https://github.com/williamboman/mason-lspconfig.nvim)
- [`neovim/nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig) >= 1.0.0

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
    ---
    -- Define the features to be enabled (if supported) when the LSP attaches
    --
    -- Possible values are:
    --   "textDocument/documentHighlight",
    --   "textDocument/inlayHint",
    --   "textDocument/codeLens",
    features = {},

    ---
    -- Define the keymaps to be set for the buffer when the LSP attaches. The
    -- syntax is similar to Lazy nvim.
    -- 
    -- Examples:
    --   ["[d"] = { vim.diagnostic.goto_prev },
    --   ["]d"] = { vim.diagnostic.goto_next },
    --   ["K"] = { vim.lsp.buf.hover, desc = "Show lsp hover" },
    keys = {}

    ---
    -- Will be passed when the LSP attaches. Alternatively, use `LspAttach` event.
    -- You can manually manage LSP features or keymaps in here as well.
    on_attach = function(client, bufnr) end,

    ---
    -- will be passed to every LSP. Can also be defined as Lua table, ex. `capabilities = {}`
    capabilities = function()
        return vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities())
    end,

    ---
    -- Provide globally required mason tools; will be installed upon `require("quarry").setup()`
    tools = {},

    ---
    -- Provide specific LSP configuration here. Every config can have the following shape:
    -- 	
    -- servers = {
    --   lua_ls = {
	--     -- Specify the filetypes when to install the tools
	--     ---@type string[]
	--     filetypes = { "lua" }, -- optional
	--     -- List of tools to install for the server
	--     ---@type string[]
	--     tools = { "lua_ls", "stylua", "luacheck" }, -- LSP itself needs to be specified
	--     -- The LSP-specific options
	--     ---@type table<any, any>
	--     config = {
    --       settings = { telemetry = { enable = false } } ,
    --     },
    --   }
    -- }
    servers = {},

    ---
    -- Provide LSP-specific handler functions or override the default. A setup handler with `_`
    -- as the key will be used as default if no LSP-specific one is defined.
    setup = {
        _ = function(name, opts)
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
- `lua/plugins/extras/lua.lua` for [Lua LSP](https://github.com/LuaLS/lua-language-server) specific configuration
- `lua/plugins/extras/typescript.lua` for [Typescript LSP](https://github.com/typescript-language-server/typescript-language-server) specific configuration
- ...extend with other LSP as you like

<details>
<summary>Setup <b>quarry.nvim</b> in <code>lua/plugins/lsp.lua</code></summary>

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

        ---
        -- This takes advantage of lazy.nvim loading mechanism and makes Lazy aware to
        -- load modules from within /lua/plugins/extras/*
        --
        -- Alternatively, you can add this to lua/init.lua:
        --  
        --   -- ... require lazy.nvim as you usually would. Check out the documentation for detailed instructions ...
        --   require("lazy").setup({
        --       { import = "plugins" },
        --       { import = "extras" }, -- <- this is the relevant line, BTW
        --   }, {
        --       -- .. regular lazy.nvim configuration ...
        --   })
        { import = "plugins.extras" },
    },
    config = {
        features = {
            "textDocument/documentHighlight",
            "textDocument/inlayHint",
            -- "textDocument/codeLens",
        },

        keys = {
            ["[d"] = { vim.diagnostic.goto_prev },
            ["]d"] = { vim.diagnostic.goto_next },
            ["K"]  = { vim.lsp.buf.hover, desc = "Show lsp hover" },
            ["gD"] = { vim.lsp.buf.declaration, desc = "[G]oto [D]eclaration" },
            ["gs"] = { vim.lsp.buf.signature_help, desc = "[G]oto [s]ignature" },
            ["gd"] = { vim.lsp.buf.definition, desc = "[G]oto [d]efinition" },
            ["gr"] = { vim.lsp.buf.references, desc = "[G]oto [r]eferences" },
            ["gi"] = { vim.lsp.buf.implementation, desc = "[G]oto [i]mplementation" },
            ["gt"] = { vim.lsp.buf.type_definition, desc = "Goto [t]ype definition" },

            ["<leader>a"] = { vim.lsp.buf.code_action, desc = "Code [a]ction" },
            ["<leader>r"] = { vim.lsp.buf.rename, desc = "[R]ename word under cursor within project" },
            ["<leader>h"] = {
                function()
                    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
                end,
                desc = "Toggle inlay [h]int",
            },

            -- vim.api.nvim_command('inoremap <C-space> <C-x><C-o>')
            ["<C-space>"] = { "<C-x><C-o>", mode = "i", remap = false },
        }

        on_attach = function(client, bufnr)
            -- Enable completion triggered by <c-x><c-o>
            vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
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
</details>

<details>
<summary>Setup lua-language-server in <code>lua/plugins/extras/lua.lua</code></summary>

```lua
-- file: lua/plugins/extras/lua.lua
return {
    "rudionrails/quarry.nvim",
    config = {
        servers = {
            lua_ls = {
                tools = {
                    "lua_ls",
                    "stylua",
                    "luacheck",

                     -- only install when opening a file associated with lua_ls
                     -- this can be set as `filetypes` or will be automatically
                     -- taken from lspconfig
                    lazy = true,
                },

                config = {
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
<summary>Setup typescript-language-server in <code>lua/plugins/extras/typescript.lua</code></summary>

```lua
-- file: lua/plugins/extras/typescript.lua
return {
    "rudionrails/quarry.nvim",
    config = {
        servers = {
            ts_ls = {
                tools = {
                    "ts_ls",
                    "prettier", -- prettierd as alternative
                    "eslint", -- eslint_d as alternative

                    -- only install when file associated with 'ts_ls' is opened
                    lazy = true,
                },

                config = {
                    completions = { completeFunctionCalls = true },
                    init_options = {
                        preferences = {
                            includeInlayParameterNameHints = "all",
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
