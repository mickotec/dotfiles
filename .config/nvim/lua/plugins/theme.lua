-- Dynamically load the active Omarchy theme from the user's state directory.
-- Using dofile avoids fragile relative symlinks that break when ~/.config/nvim
-- is managed by GNU Stow or git inside ~/dotfiles.
local theme_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(theme_file) == 1 then
	return dofile(theme_file)
else
	return {
		{
			"LazyVim/LazyVim",
			opts = {
				colorscheme = "tokyonight",
			},
		},
	}
end
