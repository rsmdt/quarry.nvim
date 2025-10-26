# Changelog

## [5.0.0](https://github.com/rsmdt/quarry.nvim/compare/v4.0.0...v5.0.0) (2025-10-26)


### ⚠ BREAKING CHANGES

* Removes fallbacks for deprecations

### Features

* add NeoVim 0.11 native LSP API support ([fa8093e](https://github.com/rsmdt/quarry.nvim/commit/fa8093e630e6603354a982896242eaba6e00a9a2))
* Removes fallbacks for deprecations ([dc57a5d](https://github.com/rsmdt/quarry.nvim/commit/dc57a5d15fdc867abb45dfe0d917b2642252fa91))


### Bug Fixes

* reverts mason default config ([09508eb](https://github.com/rsmdt/quarry.nvim/commit/09508eb7fdcdcbe2e1f91909fbb295a08979f1d9))

## [4.0.0](https://github.com/rudionrails/quarry.nvim/compare/v3.0.1...v4.0.0) (2024-11-02)


### ⚠ BREAKING CHANGES

* installer is not lazy by default, can be added with 'lazy = true'
* renames 'ensure_insgalled' to 'tools' for consistency
* server 'opts' is renamed to 'config'

### Features

* installer is not lazy by default, can be added with 'lazy = true' ([57567c3](https://github.com/rudionrails/quarry.nvim/commit/57567c3d338fae08f65535035b5e8d5d05533d57))
* renames 'ensure_insgalled' to 'tools' for consistency ([7171598](https://github.com/rudionrails/quarry.nvim/commit/7171598d878e94b2849e62aef7ae6ba8a8632f28))
* server 'opts' is renamed to 'config' ([276f89f](https://github.com/rudionrails/quarry.nvim/commit/276f89f7fc240a50a9d8e0dc14f28a79562e8fd7))

## [3.0.1](https://github.com/rudionrails/quarry.nvim/compare/v3.0.0...v3.0.1) (2024-09-23)


### Bug Fixes

* Removes print debugging statement ([2e14685](https://github.com/rudionrails/quarry.nvim/commit/2e14685a6c9c1ca0478db272028059ec22eb807e))
* when package is not available in Mason, then display a message instead of throwing an error ([01e2ca6](https://github.com/rudionrails/quarry.nvim/commit/01e2ca627f415167f3a3ef740cf558e2037d7df7))

## [3.0.0](https://github.com/rudionrails/quarry.nvim/compare/v2.3.0...v3.0.0) (2024-09-23)


### ⚠ BREAKING CHANGES

* Removes lsp feature presets
* Keys are now key-value pairs, not index-based tables

### Features

* Keys are now key-value pairs, not index-based tables ([f8767d5](https://github.com/rudionrails/quarry.nvim/commit/f8767d5bd9413b9c9074acd42050ee31087682cb))
* Removes lsp feature presets ([f25aef8](https://github.com/rudionrails/quarry.nvim/commit/f25aef826d620b7e393d99cb673a394b9cc67b76))

## [2.3.0](https://github.com/rudionrails/quarry.nvim/compare/v2.2.0...v2.3.0) (2024-07-28)


### Features

* keymap rhs do not get client & buffer passed ([e08b067](https://github.com/rudionrails/quarry.nvim/commit/e08b067b7387f127ded523e4746763cf40a6a22a))

## [2.2.0](https://github.com/rudionrails/quarry.nvim/compare/v2.1.0...v2.2.0) (2024-07-27)


### Features

* Adds Lazy-like keys feature to attach to buffer ([cd95f95](https://github.com/rudionrails/quarry.nvim/commit/cd95f952b0c4e68116937545e69c9d760b4d0c00))

## [2.1.0](https://github.com/rudionrails/quarry.nvim/compare/v2.0.0...v2.1.0) (2024-07-23)


### Features

* Adds ability to provide feature preset, list or granular detailed definitions ([a15099e](https://github.com/rudionrails/quarry.nvim/commit/a15099e1df6cc94e2882a46f3c567e3e835656ad))
* Adds configurable lsp.Client features ([3368ec0](https://github.com/rudionrails/quarry.nvim/commit/3368ec0f52481484330cfb3d12ca6e3c3076581b))

## [2.0.0](https://github.com/rudionrails/quarry.nvim/compare/v1.1.0...v2.0.0) (2024-07-18)


### ⚠ BREAKING CHANGES

* Changes setup functions to be outside the servers table

### Features

* Changes setup functions to be outside the servers table ([bf028f2](https://github.com/rudionrails/quarry.nvim/commit/bf028f2b1a3e008acc7e2e1567c12594113c7bf0))

## [1.1.0](https://github.com/rudionrails/quarry.nvim/compare/v1.0.0...v1.1.0) (2024-07-18)


### Features

* Adds _ as fallback server option ([396a26a](https://github.com/rudionrails/quarry.nvim/commit/396a26a0c5ad9a311084e02472be94917f1043a4))
