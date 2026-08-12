return {
	"milanglacier/minuet-ai.nvim",
	-- credproxyd cannot currently prove an installed executable-bound caller
	-- and exact POST /v1/messages operation.  Fail closed; never inspect or
	-- copy credential material into Neovim/Lua/argv/config.
	enabled = false,
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
