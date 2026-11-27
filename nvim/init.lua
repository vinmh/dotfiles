-- Load Config files
local config_files = {
  'options',
  'keymaps',
  'plugins',
  'colorscheme',
  'lsp',
  'tree',
}

for _, name in ipairs(config_files) do
  require(name)
end
