return {
	{ "kylechui/nvim-surround", version = "^2", event = "VeryLazy", opts = {} },
	{ "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },
	{ "folke/which-key.nvim", event = "VeryLazy", opts = {} },
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics (Trouble)" },
		},
		opts = {},
	},
}
