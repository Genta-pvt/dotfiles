vim.keymap.set('i', 'jj', '<Esc>')

-- コマンドライン（: / ? 入力中）も jj で中止する。<C-c> はコマンドラインを
-- 必ず破棄して Normal へ戻る（<Esc> は環境により実行扱いになる場合があるため避ける）。
-- 注意: コマンドラインに文字列 "jj" を打ちたい場合は <C-v>j などで回避する。
-- skkeleton 有効中の cmdline では skkeleton 側の jj=escape が先に効くため衝突しない。
vim.keymap.set('c', 'jj', '<C-c>', { desc = 'コマンドラインを jj で中止' })

-- insert モードにコマンドを持たない制御キーの「制御文字 誤挿入」対策。
-- Ctrl+英字は ASCII 制御コード（C-a=0x01 … C-z=0x1a）を端末へ送る。Neovim の insert
-- モードにコマンドが割り当てられている制御キー（C-a/C-r/C-t/C-u/C-w/C-y 等）はそれぞれの
-- 動作をするが、コマンドを持たない制御キーは生の制御文字がそのままバッファへ落ちる
-- （端末経路特有の挙動で、nvim_feedkeys を使う headless では再現しない）。
-- 公式 doc の insert.txt タグ照合で該当するのは C-b(^B) / C-f(^F) / C-z(^Z) の3つ
-- （C-l/C-s も無コマンドだが、各々 skkeleton 無効化・保存に割当済みのため落ちない）。
-- いずれも insert では使わないため <Nop> で握り潰し、ゴミ挿入を断つ。
-- 副次効果: SKK 変換中（▽/▼）に暴発してもバッファが変わらず、▽ が迷子になる desync を防ぐ。
-- Normal モードの C-f/C-b（ページ送り）・C-z（サスペンド）は insert 限定マップのため不変。
vim.keymap.set('i', '<C-f>', '<Nop>', { desc = 'insert: 制御文字 ^F の誤挿入を防ぐ' })
vim.keymap.set('i', '<C-b>', '<Nop>', { desc = 'insert: 制御文字 ^B の誤挿入を防ぐ' })
vim.keymap.set('i', '<C-z>', '<Nop>', { desc = 'insert: 制御文字 ^Z の誤挿入を防ぐ' })

-- <C-_>（^_ 0x1F）と <C-\>（^\ 0x1C）も同じ仲間だが、発生経路と条件が異なるため別記する。
-- JIS 配列には \ を打つ物理キーが2つ（¥ と ろ）あり、Ctrl との同時押しで端末はそれぞれ
-- 別の制御コードを送ってくる（片方は 0x1F=^_、隣は 0x1C=^\。挿入される制御文字から特定）。
-- Neovim の受信キーはそれぞれ <C-_> / <C-\> になるため、両方に <Nop> を張る必要がある。
-- i_CTRL-_ は 'allowrevins'（既定オフ）有効時のみ revins トグルとして働くコマンドで、
-- オフの間はコマンドにならず生の ^_ がバッファへ落ちる。
-- i_CTRL-\ は <C-\><C-n> 等2キーコマンドのプレフィックスだが insert では使わないため
-- マップで覆い隠す（ユーザーマップは組み込みの2キー解釈より優先され、単押しの ^\ 混入を断てる）。
vim.keymap.set('i', '<C-_>',  '<Nop>', { desc = 'insert: 制御文字 ^_ の誤挿入を防ぐ（Ctrl+\\ 系キーで発生）' })
vim.keymap.set('i', '<C-\\>', '<Nop>', { desc = 'insert: 制御文字 ^\\ の誤挿入を防ぐ（Ctrl+\\ 系キーで発生）' })

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
