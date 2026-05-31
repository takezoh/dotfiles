return {
	{
		"williamboman/mason.nvim",
		opts = {},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "mason.nvim" },
		opts = {
			ensure_installed = {
				"clangd",
				"pyright",
				-- "gopls",  -- requires go to be installed
				"rust_analyzer",
				"ts_ls",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "mason.nvim", "mason-lspconfig.nvim" },
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
				callback = function(ev)
					local map = function(lhs, rhs, desc)
						vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
					end
					map("gd", vim.lsp.buf.definition, "Go to definition")
					map("gr", vim.lsp.buf.references, "Find references")
					map("K", vim.lsp.buf.hover, "Hover info")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
					map("<leader>cd", "<cmd>Trouble diagnostics toggle<cr>", "Diagnostics list")
				end,
			})

			-- nvim 0.11+ vim.lsp.config API
			local servers = { "clangd", "pyright", "rust_analyzer", "ts_ls" }
			for _, server in ipairs(servers) do
				vim.lsp.config(server, {})
				vim.lsp.enable(server)
			end
		end,
	},
}
