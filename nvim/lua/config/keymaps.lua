vim.keymap.set('i', 'jj', '<Esc>')

-- 全文をクリップボードへヤンク（バッファは残す）
-- clipboard=unnamedplus 設定済みのため、無名レジスタへのヤンクで
-- そのままクリップボードに入る。:%y はカーソル位置を動かさない
vim.keymap.set('n', '<Leader>y', '<Cmd>%y<CR>', { desc = '全文をクリップボードへコピー' })

-- セッションを一覧から選択して読み込み（session.lua の :SessionSelect 相当）
vim.keymap.set('n', '<Leader>s', '<Cmd>SessionSelect<CR>', { desc = 'セッションを選択して読み込み' })

-- バッファ一覧をファジーファインダーで選択（mini.pick の :Pick buffers 相当）
vim.keymap.set('n', '<Leader>f', '<Cmd>Pick buffers<CR>', { desc = 'バッファ一覧から選択' })
