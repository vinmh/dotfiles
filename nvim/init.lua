-- Load Config files
local config_files = {
  'options',
  'keymaps',
  'plugins',
  'colorscheme',
  'lsp'
}

for n in pairs(config_files) do
  require(config_files[n])
end
