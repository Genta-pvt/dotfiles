vim.opt.clipboard:append('unnamedplus,unnamed')

-- タブ関係
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.shiftround = true

vim.opt.fileencodings = "ucs-bom,utf-8,iso-2022-jp-3,euc-jp,cp932"
vim.opt.fileformats = "unix,dos,mac"

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.scrolloff = 3
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.termguicolors = true

-- 検索・置換
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "split"

vim.opt.shada = "!,'100,<50,s10,h,%"
