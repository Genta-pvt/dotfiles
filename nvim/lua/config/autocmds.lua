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
-- markdown: treesitter ハイライト + conceal で見た目を簡潔化
-- -------------------------------------------------------
-- 目的: markdown のリンク等が冗長に見える問題を解消する。
-- markdown / markdown_inline パーサーは Neovim 本体に同梱されているため
-- プラグイン追加は不要で、treesitter ハイライトを開始すれば組み込みクエリの
-- conceal 定義が効く（[text](url) → text だけ表示、強調マーカー * _ ` も畳む等）。
-- 対象は markdown に限定する（他言語パーサーは未同梱で、グローバル有効化は無意味なため）。
-- conceallevel=2: conceal 定義のある箇所を畳む。concealcursor は既定（空）のままにし、
-- カーソルがある行は raw 表示に戻す＝URL 編集時はその行へ移動すれば元の記法が見える。
-- pcall: 万一パーサー未導入の環境でもエラーで FileType 処理が止まらないよう保護する。
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('MarkdownConceal', { clear = true }),
  pattern = 'markdown',
  callback = function()
    pcall(vim.treesitter.start)
    vim.opt_local.conceallevel = 2
  end,
})

-- -------------------------------------------------------
-- ステータスライン: 未保存フラグ [+] だけを明るい色で強調
-- -------------------------------------------------------
-- options.lua の statusline が未保存フラグ %m を %#StatusLineModified#…%* で囲み、
-- [+] 部分だけをこの色にする。バー本体（StatusLine の明るい背景）は無改変＝非破壊。
-- 色をハードコードすると colorscheme 変更時に浮くため、既存グループへ link する。
-- Title（minischeme ではシアン #42f7ff）へ寄せるのは、背景を持たず鮮やかな前景色で、
-- バーの暖色系の通常文字色（#d5dc81 淡い黄緑）と最も対照的なため [+] が強く目立つ。
-- WarningMsg 等の暖色は通常文字色と同系で目立ちにくかったので、寒色のシアンに変更した。
-- ColorScheme イベントで当て直すのは、colorscheme 側が同名グループを再定義して
-- link を上書きするケース（draft_skk.md の透明化解除での再読み込み含む）に備えるため。
local function set_statusline_modified_hl()
  vim.api.nvim_set_hl(0, 'StatusLineModified', { link = 'Title' })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('StatuslineModifiedHl', { clear = true }),
  callback = set_statusline_modified_hl,
})

-- 起動時の colorscheme は既に適用済みのため、ここで一度明示的に当てておく
set_statusline_modified_hl()

-- -------------------------------------------------------
-- draft_skk*.md 専用: バッファ滞在中のみ背景を透明化
-- -------------------------------------------------------

-- :t でパス部分を除いたファイル名のみを取得するため、ファイルがどこにあっても判定できる。
-- 完全一致でなく「draft_skk で始まり .md で終わる」前方一致にすることで、
-- :DraftNew の採番ファイル（draft_skk_2.md 等）や手動命名（draft_skk_mail.md 等）も
-- 同じ下書き扱い（透明化・<Leader>j）になる
local function is_draft_skk(buf)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t')
  return name:match('^draft_skk.*%.md$') ~= nil
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
-- draft_skk*.md 専用: バッファローカルキーマップ
-- -------------------------------------------------------
-- 全文切り取りは他のファイルで誤爆すると痛い操作のため、
-- 下書きバッファ（draft_skk*.md）限定のバッファローカルマップにする

vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('DraftSkkKeymap', { clear = true }),
  callback = function(ev)
    if not is_draft_skk(ev.buf) then return end
    -- 全文をクリップボードへ切り取り（normal に留まる）
    vim.keymap.set('n', '<Leader>j', 'ggdG',
      { buffer = ev.buf, desc = '全文をクリップボードへ切り取り' })
  end,
})

-- -------------------------------------------------------
-- :DraftNew — 下書きバッファを自動採番で開く
-- -------------------------------------------------------
-- 割り込みタスク（メール作成中のチャット返信等）のたびに名前を考える負担を無くすため、
-- 引数なしで cwd に draft_skk.md → draft_skk_2.md → draft_skk_3.md … と空き番号を探して開く。
-- 中身が空（空行のみ）の既存 draft があれば新規作成せずそれを再利用する。
-- <Leader>j（全文切り取り）後のバッファは空になるため、使い終わった下書きが自然に
-- リサイクルされ、採番ファイルが無限に増えない。

-- draft ファイル名から採番番号を得る（draft_skk.md=1、draft_skk_2.md=2 …）。
-- 数値でないサフィックス（draft_skk_mail.md 等の手動命名）は nil を返して
-- 採番・再利用の管理外にする（意図して付けた名前の中身を勝手に再利用先にしないため）
local function draft_number(name)
  if name == 'draft_skk.md' then return 1 end
  local n = name:match('^draft_skk_(%d+)%.md$')
  return n and tonumber(n) or nil
end

-- 行リストが「空（空行のみ）」かどうか
local function lines_are_blank(lines)
  for _, line in ipairs(lines) do
    if not line:match('^%s*$') then return false end
  end
  return true
end

vim.api.nvim_create_user_command('DraftNew', function()
  -- 候補は cwd 直下の draft_skk*.md。ディスク上のファイルに加えて読み込み済みバッファも
  -- 走査する（:DraftNew 直後の未保存バッファはディスクに無く、見ないと番号が衝突するため）
  local drafts = {}  -- 番号 → { path = ディスク上の相対パス, buf = バッファ番号 }

  for _, path in ipairs(vim.fn.glob('draft_skk*.md', false, true)) do
    local num = draft_number(vim.fn.fnamemodify(path, ':t'))
    if num then drafts[num] = { path = path } end
  end

  local cwd = vim.fn.getcwd()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.api.nvim_buf_is_loaded(buf) and name ~= ''
        and vim.fn.fnamemodify(name, ':p:h') == cwd then
      local num = draft_number(vim.fn.fnamemodify(name, ':t'))
      if num then
        drafts[num] = drafts[num] or {}
        drafts[num].buf = buf
      end
    end
  end

  -- 再利用判定: 番号の小さい順に、空（空行のみ）の draft を探す。
  -- バッファが読み込み済みならバッファ内容を優先する（<Leader>j 切り取り直後は
  -- 未保存でバッファだけ空、というケースをディスク内容より正しく反映するため）
  local numbers = vim.tbl_keys(drafts)
  table.sort(numbers)
  for _, num in ipairs(numbers) do
    local d = drafts[num]
    local blank
    if d.buf then
      blank = lines_are_blank(vim.api.nvim_buf_get_lines(d.buf, 0, -1, false))
    else
      blank = lines_are_blank(vim.fn.readfile(d.path))
    end
    if blank then
      if d.buf then
        -- 読み込み済みバッファはそのまま切り替える（:edit だと未保存の空状態へ
        -- ディスク内容が絡む再読込・E37 の懸念があるため API で直接移動する）
        vim.api.nvim_set_current_buf(d.buf)
      else
        vim.cmd.edit(d.path)
      end
      return
    end
  end

  -- 空きが無ければ最小の未使用番号で新規作成
  local n = 1
  while drafts[n] do n = n + 1 end
  vim.cmd.edit(n == 1 and 'draft_skk.md' or ('draft_skk_%d.md'):format(n))
end, { desc = '下書きバッファを自動採番で開く（空 draft があれば再利用）' })

-- -------------------------------------------------------
-- draft_skk*.md: 起動時に同ディレクトリの書きかけ draft を復元
-- -------------------------------------------------------
-- draft の切り替えはバッファリスト（<Leader>f = Pick buffers）経由で行うため、
-- `nvim ./draft_skk.md` で起動した時点で、前回書きかけのまま残した draft も
-- リストに載っていてほしい。VimEnter で「起動バッファが draft のとき」だけ、
-- 同じディレクトリの空でない draft_skk*.md を :badd で追加する。
--   - 空 draft を載せないのは、リストのノイズになるだけで、必要になれば
--     :DraftNew が勝手に再利用するため
--   - draft 以外のファイルで起動した通常の編集作業では何もしない
--   - :badd は読み込みを遅延したままリストへ登録するだけなので起動は重くならない
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('DraftSkkRestore', { clear = true }),
  callback = function()
    if not is_draft_skk(0) then return end
    local dir = vim.fn.expand('%:p:h')
    for _, path in ipairs(vim.fn.glob(dir .. '/draft_skk*.md', false, true)) do
      -- 起動引数で開いたファイル自身（既にバッファが存在する）は除外する
      if vim.fn.bufexists(path) == 0 and not lines_are_blank(vim.fn.readfile(path)) then
        vim.cmd('badd ' .. vim.fn.fnameescape(path))
      end
    end
  end,
})
