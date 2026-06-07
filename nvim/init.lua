-- lazy.nvim がなければ自動クローン
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lua/config/plugins/ 以下のプラグイン定義を一括読み込み
require('lazy').setup('config.plugins')

-- オプション・キーマップ・オートコマンドを各モジュールから読み込み
require('config.options')
require('config.keymaps')
require('config.autocmds')
require('config.skkeleton')
