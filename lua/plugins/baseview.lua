return {
  {
    dir = vim.fn.expand("~/tools/baseview.nvim"),
    name = "baseview.nvim",
    main = "baseview",
    lazy = false,
    init = function()
      vim.filetype.add({ extension = { base = "yaml" } })
    end,
    config = function()
      require("baseview").setup({
        vault = "/path/to/vault",
        python = vim.fn.exepath("python3"),
        auto_open = true,
      })
    end,
  },
}
