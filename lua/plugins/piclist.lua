return {
  {
    dir = "/path/to/vault/nvim-piclist",
    name = "nvim-piclist",
    config = function()
      require("piclist").setup({
        endpoint = "http://127.0.0.1:36677/upload",
        enabled = false,
      })
    end,
  },
}
