vim.keymap.set('i', 'jj', '<Esc>')

-- コマンドライン（: / ? 入力中）も jj で中止する。<C-c> はコマンドラインを
-- 必ず破棄して Normal へ戻る（<Esc> は環境により実行扱いになる場合があるため避ける）。
-- 注意: コマンドラインに文字列 "jj" を打ちたい場合は <C-v>j などで回避する。
-- skkeleton 有効中の cmdline では skkeleton 側の jj=escape が先に効くため衝突しない。
vim.keymap.set('c', 'jj', '<C-c>', { desc = 'コマンドラインを jj で中止' })

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

-- , : 直前 f/t/F/T の逆方向へ行跨ぎジャンプ（mini.jump の ; に対する逆 repeat）。
-- mini.jump は ;（repeat_jump）だけをマップし , は提供しないため、ここで補う。
-- MiniJump.state.backward（直前ジャンプの向き）を反転して MiniJump.jump へ渡し、
-- 行跨ぎ探索自体は mini.jump 本体に任せる。jump 呼び出しで state.backward が
-- 書き換わるので元の向きへ復元し、; が常に「元の f 方向」を維持するようにする
-- （こうすると , を連打しても native 同様に同一方向へ進み続ける）。
-- operator-pending(o) は mini.jump が expr で扱うため対象に含めず、d, 等は native のままにする。
vim.keymap.set({ 'n', 'x' }, ',', function()
  local s = MiniJump.state
  if s.target == nil then return end  -- まだ一度も f/t していなければ何もしない
  local orig = s.backward
  MiniJump.jump(s.target, not orig, s.till)
  s.backward = orig                   -- ; の基準方向を元に戻す
end, { desc = 'mini.jump: 直前ジャンプの逆方向へ' })

-- gV: 直前に変更/貼り付けた範囲を、その種類（文字/行/矩形）に応じて Visual 選択する。
-- 例: 貼り付け直後に gV → 貼った範囲を選択 → = で整形、> でインデント
-- rhs は mini.basics と同一（`[ と `] の間を getregtype の種類で選択）
vim.keymap.set('n', 'gV', '"g`[" . strpart(getregtype(), 0, 1) . "g`]"',
  { expr = true, replace_keycodes = false, desc = '直前に変更した範囲を選択' })

-- <C-s>: どのモードからでも保存（変更があるときだけ書き込む :update）。
-- Insert / Visual からは一度 Normal に戻ってから保存する。
-- :update は書き込み時に「"file" 41L, 1234B written」を自動表示し、
-- 変更が無ければ何も出さない。保存失敗時はエラーがそのまま見える。
-- 注意: 端末によっては <C-s> がフロー制御(XOFF)で画面を固める（<C-q> で解除）
vim.keymap.set('n', '<C-s>', '<Cmd>update<CR>', { desc = '保存' })
vim.keymap.set({ 'i', 'x' }, '<C-s>', '<Esc><Cmd>update<CR>', { desc = '保存して Normal へ' })

-- 空行挿入は Neovim 0.11 組み込みデフォルトの [<Space> / ]<Space>（上/下に空行、count 対応）に任せる。
-- 自作 go / gO は同じく組み込みの gO（document symbol = 見出し目次）と衝突するため廃止した。
