vim.keymap.set('i', 'jj', '<Esc>')

-- 全文をクリップボードへヤンク（バッファは残す）
-- clipboard=unnamedplus 設定済みのため、無名レジスタへのヤンクで
-- そのままクリップボードに入る。:%y はカーソル位置を動かさない
vim.keymap.set('n', '<Leader>y', '<Cmd>%y<CR>', { desc = '全文をクリップボードへコピー' })

-- セッションを一覧から選択して読み込み（session.lua の :SessionSelect 相当）
vim.keymap.set('n', '<Leader>s', '<Cmd>SessionSelect<CR>', { desc = 'セッションを選択して読み込み' })

-- バッファ一覧をファジーファインダーで選択（mini.pick の :Pick buffers 相当）
vim.keymap.set('n', '<Leader>f', '<Cmd>Pick buffers<CR>', { desc = 'バッファ一覧から選択' })

-- ============================================================
-- mini.basics 由来のキーマップ（mini に依存せず explicit に記述）
-- ============================================================

-- j / k: count 無しのときは表示行単位で移動（折り返した行を1見た目行ずつ動ける）。
-- 3j のように count 付きなら通常の行移動になり、相対行ジャンプは壊れない
vim.keymap.set({ 'n', 'x' }, 'j', [[v:count == 0 ? 'gj' : 'j']],
  { expr = true, desc = 'count 無しは表示行で下移動' })
vim.keymap.set({ 'n', 'x' }, 'k', [[v:count == 0 ? 'gk' : 'k']],
  { expr = true, desc = 'count 無しは表示行で上移動' })

-- gV: 直前に変更/貼り付けた範囲を、その種類（文字/行/矩形）に応じて Visual 選択する。
-- 例: 貼り付け直後に gV → 貼った範囲を選択 → = で整形、> でインデント
-- rhs は mini.basics と同一（`[ と `] の間を getregtype の種類で選択）
vim.keymap.set('n', 'gV', '"g`[" . strpart(getregtype(), 0, 1) . "g`]"',
  { expr = true, replace_keycodes = false, desc = '直前に変更した範囲を選択' })

-- <C-s>: どのモードからでも保存（変更があるときだけ書き込む :update）。
-- Insert / Visual からは一度 Normal に戻ってから保存する。
-- 注意: 端末によっては <C-s> がフロー制御(XOFF)で画面を固める（<C-q> で解除）
vim.keymap.set('n', '<C-s>', '<Cmd>silent! update | redraw<CR>',
  { desc = '保存' })
vim.keymap.set({ 'i', 'x' }, '<C-s>', '<Esc><Cmd>silent! update | redraw<CR>',
  { desc = '保存して Normal へ' })

-- go / gO: カーソル位置を保ったまま下/上に空行を挿入する（挿入モードに入らない）。
-- count 対応（3go で空行3つ）。unimpaired の ]<Space> / [<Space> と同等の操作。
-- ※ mini.basics は operatorfunc でドットリピート対応だが、ここでは挙動を単純化している
local function put_empty_lines(above)
  local count = vim.v.count1
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local insert_at = above and (row - 1) or row  -- 0-based の挿入位置
  local blanks = {}
  for _ = 1, count do
    blanks[#blanks + 1] = ''
  end
  vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, blanks)
  -- 上に挿入したときは元の行が下へずれるので、カーソルを元の行へ戻す
  if above then
    vim.api.nvim_win_set_cursor(0, { row + count, col })
  end
end

vim.keymap.set('n', 'go', function() put_empty_lines(false) end,
  { desc = 'カーソル下に空行を挿入' })
vim.keymap.set('n', 'gO', function() put_empty_lines(true) end,
  { desc = 'カーソル上に空行を挿入' })
