return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		suggestion = {
			auto_trigger = true,
			keymap = {
				accept = "<A-y>",
				next = "<A-]>",
				prev = "<A-[>",
				dismiss = "<A-e>",
			},
		},
	},
}
