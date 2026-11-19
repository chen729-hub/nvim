-- Obsidian vault integration. Markdown rendering and completion remain owned
-- by render-markdown.nvim and the existing nvim-cmp LSP source.
local vault = require("config.local_settings").vault_path
if not vault then return {} end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cmd = "Obsidian",
    dependencies = { "nvim-lua/plenary.nvim" },
    init = function()
      vim.g.obsidian_default_keymap = false
    end,
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "main",
          path = vault,
        },
      },
      completion = { min_chars = 2 },
      picker = { name = "telescope.nvim" },
      ui = { enable = false },
    },
  },
}
