return {
	"milanglacier/minuet-ai.nvim",
	enabled = vim.env.ANTHROPIC_API_KEY ~= nil and vim.env.ANTHROPIC_API_KEY ~= "",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		provider = "claude",
		notify = "warn",
		provider_options = {
			claude = {
				max_tokens = 512,
				model = "claude-sonnet-4-20250514",
				system = {
					type = "text",
					text = "You are a coding assistant. Complete the code concisely.",
				},
			},
		},
		blink = {
			enable_auto_complete = false,
		},
	},
}
