vim.keymap.set('i', 'jj', '<Esc>')

-- 全文をクリップボードへヤンク（バッファは残す）
-- clipboard=unnamedplus 設定済みのため、無名レジスタへのヤンクで
-- そのままクリップボードに入る。:%y はカーソル位置を動かさない
vim.keymap.set('n', '<Leader>y', '<Cmd>%y<CR>', { desc = '全文をクリップボードへコピー' })
