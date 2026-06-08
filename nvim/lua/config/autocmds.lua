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

-- ターミナルバッファを開いた直後にインサートモードへ移行
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  command = "startinsert",
})

-- -------------------------------------------------------
-- draft_skk.md 専用: バッファ滞在中のみ背景を透明化
-- -------------------------------------------------------

-- :t でパス部分を除いたファイル名のみを取得するため、ファイルがどこにあっても判定できる
local function is_draft_skk(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t') == 'draft_skk.md'
end

local transparent_groups = { 'Normal', 'NonText', 'LineNr', 'StatusLine', 'StatusLineNC' }

vim.api.nvim_create_augroup('DraftSkkTransparent', { clear = true })

-- draft_skk.md に入ったとき: 対象グループの bg を NONE にしてターミナルの背景色を透過させる
vim.api.nvim_create_autocmd('BufEnter', {
  group = 'DraftSkkTransparent',
  callback = function(ev)
    if not is_draft_skk(ev.buf) then return end
    for _, group in ipairs(transparent_groups) do
      vim.api.nvim_set_hl(0, group, { bg = 'NONE', ctermbg = 'NONE' })
    end
  end,
})

-- draft_skk.md から離れたとき: colorscheme を再読み込みして全ハイライトをリセット
-- `colorscheme <name>` は ColorScheme イベントを発火させるため、
-- プラグイン側の上書きも含めて透明化前の状態に完全に戻せる
vim.api.nvim_create_autocmd('BufLeave', {
  group = 'DraftSkkTransparent',
  callback = function(ev)
    if not is_draft_skk(ev.buf) then return end
    vim.cmd('colorscheme ' .. vim.g.colors_name)
  end,
})
