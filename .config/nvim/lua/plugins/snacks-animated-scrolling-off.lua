return {
	"folke/snacks.nvim",
	opts = {
		scroll = {
			enabled = false, -- Disable scrolling animations
		},
		picker = {
			hidden = true, -- Show hidden files by default
			sources = {
				explorer = {
					hidden = true,
				},
				files = {
					hidden = true,
				},
			},
		},
	},
}
