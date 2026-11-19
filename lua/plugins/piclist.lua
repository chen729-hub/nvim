local vault = require("config.local_settings").vault_path
if not vault then return {} end

return {
  {
    dir = vim.fs.joinpath(vault, "nvim-piclist"),
    name = "nvim-piclist",
    config = function()
      require("piclist").setup({
        endpoint = "http://127.0.0.1:36677/upload",
        enabled = false,
      })
    end,
  },
}
