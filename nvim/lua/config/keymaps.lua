vim.keymap.set('i', 'jj', '<Esc>')

-- 全バッファをクリップボードへ削除し、インサートに戻る（draft_skk.md 運用向け）
vim.keymap.set('i', '<C-y>', '<Esc>ggdGi', { desc = '全バッファをクリップボードへ削除してインサートに戻る' })
