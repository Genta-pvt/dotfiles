-- ============================================================
-- オートコマンド設定
-- ============================================================

-- -------------------------------------------------------
-- 編集補助
-- -------------------------------------------------------

-- 前回のカーソル位置を復元（shada の " マークを使用）
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('RestoreCursor', { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- -------------------------------------------------------
-- 視覚フィードバック
-- -------------------------------------------------------

-- ヤンク範囲を一瞬ハイライト表示
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  command = "startinsert",
})
