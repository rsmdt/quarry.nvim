-- Minimal init for testing quarry.nvim

-- Add the plugin to runtimepath
vim.opt.runtimepath:append(".")

-- Add plenary to runtimepath (required for testing)
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 1 then
	vim.opt.runtimepath:append(plenary_path)
end

-- Disable swapfile and other unnecessary features for testing
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Required for testing
vim.cmd([[runtime! plugin/plenary.vim]])
