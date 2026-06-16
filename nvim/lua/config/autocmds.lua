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
-- ステータスライン: 未保存フラグ [+] だけを明るい色で強調
-- -------------------------------------------------------
-- options.lua の statusline が未保存フラグ %m を %#StatusLineModified#…%* で囲み、
-- [+] 部分だけをこの色にする。バー本体（StatusLine の明るい背景）は無改変＝非破壊。
-- 色をハードコードすると colorscheme 変更時に浮くため、既存グループへ link する。
-- 警告メッセージ（WarningMsg）へ寄せるのは、意味的に「注意＝未保存」と一致し、
-- 背景を持たず明るい前景色のため、バーの上で [+] だけが明るく浮き立つため。
-- ColorScheme イベントで当て直すのは、colorscheme 側が同名グループを再定義して
-- link を上書きするケース（draft_skk.md の透明化解除での再読み込み含む）に備えるため。
local function set_statusline_modified_hl()
  vim.api.nvim_set_hl(0, 'StatusLineModified', { link = 'WarningMsg' })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('StatuslineModifiedHl', { clear = true }),
  callback = set_statusline_modified_hl,
})

-- 起動時の colorscheme は既に適用済みのため、ここで一度明示的に当てておく
set_statusline_modified_hl()

-- -------------------------------------------------------
-- draft_skk.md 専用: バッファ滞在中のみ背景を透明化
-- -------------------------------------------------------

-- :t でパス部分を除いたファイル名のみを取得するため、ファイルがどこにあっても判定できる
local function is_draft_skk(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t') == 'draft_skk.md'
end

-- StatusLineModified も含める：下書き中に未保存になっても警告色を出さず、ステータスラインを透明に保つ
local transparent_groups = { 'Normal', 'NonText', 'LineNr', 'StatusLine', 'StatusLineNC', 'StatusLineModified' }

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

-- -------------------------------------------------------
-- draft_skk.md 専用: バッファローカルキーマップ
-- -------------------------------------------------------
-- 全文切り取りは他のファイルで誤爆すると痛い操作のため、
-- 下書きバッファ（draft_skk.md）限定のバッファローカルマップにする

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('DraftSkkKeymap', { clear = true }),
  callback = function(ev)
    if not is_draft_skk(ev.buf) then return end
    -- 全文をクリップボードへ切り取り（normal に留まる）
    vim.keymap.set('n', '<Leader>j', 'ggdG',
      { buffer = ev.buf, desc = '全文をクリップボードへ切り取り' })
  end,
})
