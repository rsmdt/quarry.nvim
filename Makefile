.PHONY: test coverage format

test:
	@echo "Running tests..."
	@nvim --headless -c "lua for _, f in ipairs(vim.fn.glob('/Users/irudi/Code/personal/lua/quarry.nvim/tests/*_spec.lua', true, true)) do print('Running: ' .. f); require('plenary.busted').run(f) end"

isolated:
	@echo "Running tests..."
	@nvim --headless --noplugin -u tests/setup.lua -c "lua require('plenary.busted').run('./tests/', {minimal_init = 'tests/setup.lua'})"

coverage:
	@echo "Running tests with coverage..."
	@nvim --headless --noplugin -u tests/setup.lua -c "lua require('luacov'); require('plenary.busted').run('tests/', {minimal_init = 'tests/setup.lua'})" -c "lua require('luacov.reporter').report()"

format:
	@echo "Formatting code with stylua..."
	@stylua .
