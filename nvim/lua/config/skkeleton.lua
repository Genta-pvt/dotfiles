-- ============================================================
-- skkeleton 設定
-- ============================================================
vim.api.nvim_create_autocmd('User', {
  pattern = 'skkeleton-initialize-pre',
  callback = function()
  vim.fn['skkeleton#register_kanatable_file'](
    'azik',
    vim.fn.expand('~/dotfiles/nvim/skk/test.yaml'),
    '',
    true
  )
  vim.fn['skkeleton#config']({
        globalDictionaries = { '~/.skk/SKK-JISYO.L' },
        eggLikeNewline     = true,
        kanaTable = 'azik',
      })
    vim.fn['skkeleton#register_kanatable']('rom', {
  jj = 'escape',
})
  end,
})

-- Insert / Command モードのトグル
vim.keymap.set('i', '<C-j>', '<Plug>(skkeleton-toggle)', { desc = 'skkeleton toggle' })
vim.keymap.set('c', '<C-j>', '<Plug>(skkeleton-toggle)', { desc = 'skkeleton toggle' })
