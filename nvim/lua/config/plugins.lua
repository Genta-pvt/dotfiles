return {
  { 'vim-jp/vimdoc-ja' },
  { 'nvim-mini/mini.nvim', version = false, config = function()
    require('mini.trailspace').setup()
  end },
}

