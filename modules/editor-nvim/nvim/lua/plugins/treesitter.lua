return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup()
		-- auto-install parsers on first interactive startup
		vim.api.nvim_create_autocmd("UIEnter", {
			once = true,
			callback = function()
				local parsers = {
					"c", "cpp", "python", "go", "rust",
					"typescript", "javascript", "lua", "vim", "vimdoc",
					"json", "yaml", "toml", "markdown", "html", "css", "glsl",
				}
				local to_install = {}
				for _, p in ipairs(parsers) do
					if not pcall(vim.treesitter.language.inspect, p) then
						table.insert(to_install, p)
					end
				end
				if #to_install > 0 then
					vim.cmd("TSInstall " .. table.concat(to_install, " "))
				end
			end,
		})
	end,
}
