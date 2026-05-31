return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"clang-format",
				"ruff",
				"prettier",
			},
		},
	},
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				c = { "clang-format" },
				cpp = { "clang-format" },
				python = { "ruff_format" },
				rust = { "rustfmt" },
				typescript = { "prettier" },
				javascript = { "prettier" },
				typescriptreact = { "prettier" },
				javascriptreact = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
			},
			format_on_save = function(bufnr)
				local disabled = { c = true, cpp = true }
				if disabled[vim.bo[bufnr].filetype] then
					return
				end
				return { timeout_ms = 3000, lsp_fallback = true }
			end,
		},
	},
}
