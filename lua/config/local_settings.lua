local path = vim.fn.stdpath("config") .. "/local.lua"
if vim.uv.fs_stat(path) then
  return dofile(path)
end
return {}
