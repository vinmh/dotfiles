-- Headless smoke test for this config.
-- Usage (from the config dir): nvim --headless -c 'luafile tests/smoke.lua'
-- Prints PASS/FAIL per check and exits non-zero if any check fails.

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local fixtures = root .. "/fixtures/"
local failures = 0
vim.o.swapfile = false

local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  io.stdout:write(("%s  %s%s\n"):format(ok and "PASS" or "FAIL", name, (not ok and detail) and (" -- " .. detail) or ""))
  io.stdout:flush()
end

-- Capture errors and warnings raised through vim.notify or the message area
local errors = {}
local notify = vim.notify
vim.notify = function(msg, level, ...)
  if level and level >= vim.log.levels.WARN then table.insert(errors, msg) end
  return notify(msg, level, ...)
end

-- Config problems lualine reports in :LualineNotices
local function lualine_notices()
  require("lualine.utils.notices").show_notices()
  local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  vim.cmd("silent! close")
  return text
end

local function messages_errors()
  local msgs = vim.fn.execute("messages")
  if msgs:find("rror") or msgs:find("traceback") then return msgs end
end

local function open(name)
  vim.cmd("silent edit! " .. fixtures .. name)
  vim.cmd.redraw()
  return vim.api.nvim_get_current_buf()
end

local function wait_client(buf, name, timeout)
  return vim.wait(timeout, function()
    local c = vim.lsp.get_clients({ bufnr = buf, name = name })[1]
    return c ~= nil and c.initialized
  end, 100)
end

local function treesitter_ok(buf)
  local ok, err = pcall(function() vim.treesitter.get_parser(buf):parse(true) end)
  return vim.treesitter.highlighter.active[buf] ~= nil and ok, err
end

-- Global keymap lookup that ignores buffer-local maps
local function global_map(mode, lhs)
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    if m.lhs == lhs then return m end
  end
end

local function buffer_map(buf, mode, lhs)
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    if m.lhs == lhs then return m end
  end
end

local function run()
  local leader = vim.g.mapleader

  -- Headless has no UI, so lazy.nvim never fires VeryLazy; simulate a UI attaching
  vim.api.nvim_exec_autocmds("UIEnter", {})
  vim.wait(2000, function() return vim.g.did_very_lazy == true end, 50)
  check("VeryLazy fired", vim.g.did_very_lazy == true)

  -- Plugins
  local plugins = require("lazy.core.config").plugins
  check("lazy plugin table populated", plugins["blink.cmp"] ~= nil and plugins["conform.nvim"] ~= nil)
  check("claudecode.nvim removed", plugins["claudecode.nvim"] == nil)

  -- Options
  check("signcolumn=yes", vim.o.signcolumn == "yes", vim.o.signcolumn)
  check("undofile on", vim.o.undofile == true)
  check("scrolloff=8", vim.o.scrolloff == 8, tostring(vim.o.scrolloff))
  check("updatetime=250", vim.o.updatetime == 250, tostring(vim.o.updatetime))
  check("colorscheme catppuccin-mocha", vim.g.colors_name == "catppuccin-mocha", vim.g.colors_name)
  -- Keep the test's throwaway files out of the user's undo dir and shada
  vim.o.undofile = false
  vim.o.shadafile = "NONE"

  -- Treesitter indent only where the language has indent queries
  vim.cmd("enew | setfiletype help")
  check("no treesitter indentexpr for vimdoc (no indents.scm)", vim.bo.indentexpr == "", vim.bo.indentexpr)
  vim.cmd("silent bwipeout!")
  local notices = lualine_notices()
  check("no lualine config notices", notices:find("###") == nil, notices)

  -- LSP servers enabled through mason-lspconfig's automatic_enable
  for _, server in ipairs({ "pylsp", "lua_ls", "rust_analyzer", "zls", "clangd", "bashls", "gopls" }) do
    check(server .. " enabled", vim.lsp.is_enabled(server))
  end

  -- Markdown: treesitter + injections + render-markdown
  local md = open("sample.md")
  local ok, err = treesitter_ok(md)
  check("markdown treesitter highlight and injections", ok, err)
  -- render-markdown renders on a debounce, so poll for its extmarks
  local marks = 0
  vim.wait(3000, function()
    marks = 0
    for name, ns in pairs(vim.api.nvim_get_namespaces()) do
      if name:find("render") then marks = marks + #vim.api.nvim_buf_get_extmarks(md, ns, 0, -1, {}) end
    end
    return marks > 0
  end, 100)
  check("render-markdown draws extmarks", marks > 0, "extmarks=" .. marks)

  -- Python: treesitter + LSP attach
  local py = open("sample.py")
  ok, err = treesitter_ok(py)
  check("python treesitter highlight", ok, err)
  check("python treesitter indentexpr", vim.bo[py].indentexpr:find("nvim%-treesitter") ~= nil, vim.bo[py].indentexpr)
  check("pylsp attaches", wait_client(py, "pylsp", 10000))
  check("LSP omnifunc set", vim.bo[py].omnifunc == "v:lua.vim.lsp.omnifunc", vim.bo[py].omnifunc)

  -- LSP keymaps (buffer-local, set on LspAttach)
  local gd = buffer_map(py, "n", "gd")
  check("gd is buffer-local LSP definition", gd ~= nil and gd.callback == vim.lsp.buf.definition)
  local grr = buffer_map(py, "n", "grr")
  check("grr opens Telescope references", grr ~= nil and (grr.rhs or ""):find("Telescope lsp_references") ~= nil)
  local cf = global_map("n", leader .. "cf")
  check("<Leader>cf formats (global)", cf ~= nil and cf.desc == "Format buffer")
  check("no <Leader>f map (prefix clash)",
    buffer_map(py, "n", leader .. "f") == nil and global_map("n", leader .. "f") == nil)
  check("no buffer-local gr map", buffer_map(py, "n", "gr") == nil)

  -- Global keymaps
  check("no global gd/gr Telescope maps", global_map("n", "gd") == nil and global_map("n", "gr") == nil)
  local resize = {
    ["<C-Up>"] = ":resize +2<CR>",
    ["<C-Down>"] = ":resize -2<CR>",
    ["<C-Left>"] = ":vertical resize -2<CR>",
    ["<C-Right>"] = ":vertical resize +2<CR>",
  }
  for lhs, rhs in pairs(resize) do
    local m = global_map("n", lhs)
    check(lhs .. " -> " .. rhs, m ~= nil and m.rhs == rhs, m and m.rhs or "unmapped")
  end
  local dnext = global_map("n", "]d")
  check("]d is the built-in default", dnext ~= nil and (dnext.desc or ""):find("diagnostic") ~= nil,
    dnext and vim.inspect(dnext.desc) or "unmapped")

  -- Lua: lua_ls knows the vim API (lazydev library)
  local lua = open("sample.lua")
  check("lua_ls attaches", wait_client(lua, "lua_ls", 15000))
  local hover_text = ""
  vim.wait(20000, function()
    local res = vim.lsp.buf_request_sync(lua, "textDocument/hover", {
      textDocument = { uri = vim.uri_from_bufnr(lua) },
      position = { line = 0, character = 30 }, -- on nvim_buf_get_lines
    }, 2000)
    for _, r in pairs(res or {}) do
      if r.result and r.result.contents then hover_text = vim.inspect(r.result.contents) end
    end
    return hover_text:find("nvim_buf_get_lines") ~= nil
  end, 500)
  check("lua_ls resolves vim.api", hover_text:find("nvim_buf_get_lines") ~= nil)

  -- Completion: blink.cmp
  py = open("sample.py")
  wait_client(py, "pylsp", 10000)
  check("blink uses the Rust fuzzy matcher", pcall(require, "blink.cmp.fuzzy.rust"))
  local client = vim.lsp.get_clients({ bufnr = py, name = "pylsp" })[1]
  local snippet_support = client and vim.tbl_get(client.config.capabilities or {},
    "textDocument", "completion", "completionItem", "snippetSupport")
  check("LSP clients get blink capabilities", snippet_support == true)
  local labels, insert_maps = {}, {}
  vim.cmd("normal! G")
  -- feedkeys with "x!" blocks in insert mode; a timer collects results and leaves insert mode
  local timer, started = vim.uv.new_timer(), vim.uv.now()
  timer:start(200, 200, vim.schedule_wrap(function()
    local items = require("blink.cmp.completion.list").items or {}
    if #items > 0 or vim.uv.now() - started > 6000 then
      timer:stop()
      for _, item in ipairs(items) do table.insert(labels, item.label) end
      for _, lhs in ipairs({ "<C-j>", "<C-k>", "<Tab>", "<S-Tab>", "<CR>", "<C-n>", "<C-p>", "<Down>", "<Up>", "<C-y>", "<C-e>" }) do
        insert_maps[lhs] = vim.fn.maparg(lhs, "i", false, true).desc or ""
      end
      vim.cmd("stopinsert")
    end
  end))
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("oos.getc", true, false, true), "tx!", false)
  vim.cmd("silent! undo")
  check("blink completes os.getc -> getcwd", vim.tbl_contains(labels, "getcwd()") or vim.tbl_contains(labels, "getcwd"),
    vim.inspect(labels))
  local expected = { ["<C-j>"] = "Select Next", ["<C-k>"] = "Select Prev", ["<Tab>"] = "Select Next",
    ["<S-Tab>"] = "Select Prev", ["<CR>"] = "Accept",
    -- keys nvim-cmp's insert preset provided
    ["<C-n>"] = "Select Next", ["<C-p>"] = "Select Prev", ["<Down>"] = "Select Next", ["<Up>"] = "Select Prev",
    ["<C-y>"] = "Accept", ["<C-e>"] = "Cancel" }
  for lhs, want in pairs(expected) do
    check("insert " .. lhs .. " -> blink " .. want, (insert_maps[lhs] or ""):find("blink") ~= nil
      and insert_maps[lhs]:find(want, 1, true) ~= nil, insert_maps[lhs])
  end

  -- Formatting: conform format-on-save
  local function save_and_read(dir, name, text)
    vim.fn.mkdir(dir, "p")
    local path = dir .. "/" .. name
    vim.fn.writefile(vim.split(text, "\n"), path)
    vim.cmd("silent edit! " .. path)
    vim.cmd("silent write")
    local content = table.concat(vim.fn.readfile(path), "\n")
    vim.cmd("silent bwipeout!")
    return content
  end
  local tmp = vim.fn.tempname()
  local py_out = save_and_read(tmp .. "/py", "fmt.py", "x=1")
  check("python formatted on save (black)", py_out == "x = 1", vim.inspect(py_out))
  local c_src = "int  main(){return 0;}"
  local c_out = save_and_read(tmp .. "/c-plain", "fmt.c", c_src)
  check("C left alone without .clang-format", c_out == c_src, vim.inspect(c_out))
  vim.fn.mkdir(tmp .. "/c-styled", "p")
  vim.fn.writefile({ "BasedOnStyle: LLVM" }, tmp .. "/c-styled/.clang-format")
  c_out = save_and_read(tmp .. "/c-styled", "fmt.c", c_src)
  check("C formatted with .clang-format", c_out ~= c_src and c_out:find("int main()", 1, true) ~= nil, vim.inspect(c_out))

  -- Git: gitsigns in a throwaway repo
  local repo = tmp .. "/repo"
  vim.fn.mkdir(repo, "p")
  vim.fn.writefile({ "one", "two" }, repo .. "/file.txt")
  vim.system({ "sh", "-c", "git init -q && git add . && git -c user.name=t -c user.email=t@t commit -qm init" },
    { cwd = repo }):wait()
  vim.fn.writefile({ "one", "changed" }, repo .. "/file.txt")
  vim.cmd("silent edit! " .. repo .. "/file.txt")
  local git_buf = vim.api.nvim_get_current_buf()
  vim.wait(5000, function()
    local s = vim.b[git_buf].gitsigns_status_dict
    return s ~= nil and (s.changed or 0) > 0
  end, 100)
  local status = vim.b[git_buf].gitsigns_status_dict
  check("gitsigns sees the changed line", status ~= nil and status.changed == 1, vim.inspect(status))
  local hunk_map = buffer_map(git_buf, "n", "]c")
  check("gitsigns ]c hunk map", hunk_map ~= nil and hunk_map.desc == "Next git hunk")
  check("gitsigns <Leader>hs map", buffer_map(git_buf, "n", leader .. "hs") ~= nil)
  vim.cmd("silent bwipeout!")
  vim.fn.delete(tmp, "rf")

  -- VeryLazy plugins
  check("which-key loaded", package.loaded["which-key"] ~= nil)
  check("window-picker loaded", package.loaded["window-picker"] ~= nil)

  -- Errors gathered during the whole run
  local msg_err = messages_errors()
  check("no error messages", msg_err == nil, msg_err)
  check("no vim.notify errors", #errors == 0, vim.inspect(errors))
end

vim.defer_fn(function()
  local ok, err = pcall(run)
  check("smoke test ran to completion", ok, err)
  io.stdout:write(failures == 0 and "ALL PASSED\n" or ("FAILURES: " .. failures .. "\n"))
  vim.cmd(failures == 0 and "qa!" or "cq!")
end, 1500)
