-- ============================================================
-- skkeleton 設定
-- skkeleton は Neovim 上で動作する SKK 日本語入力プラグイン。
-- 動作には denops.vim (Deno ランタイム) が必要。
-- ============================================================

-- 'skkeleton-initialize-pre' イベントで設定を注入する。
-- プラグインロード後・初期化前に実行されるため、設定が確実に反映される。
vim.api.nvim_create_autocmd('User', {
  pattern  = 'skkeleton-initialize-pre',
  callback = function()
    -- AZIK かなテーブルを登録（skkeleton_azik.lua で定義）
    local azik = require('config.skkeleton_azik')
    vim.fn['skkeleton#register_kanatable']('azik', azik, true)

    -- function マッピング（azik テーブルは create=true で空生成のためデフォルト rom の
    -- function が引き継がれない。必要なものをここで明示的に追加する）
    vim.fn['skkeleton#register_kanatable']('azik', {
      [' '] = 'henkanFirst', -- スペースで変換開始（▽モード → ▼モード）
      ['/'] = 'abbrev',      -- 欧文変換モード（/で英字変換開始）
      [';'] = 'henkanPoint', -- 送り仮名マーカー（l→っ 移行により ; が解放された）
      ['^'] = 'katakana',    -- 片仮名トグル（標準 SKK の q に相当。本設定は q=ん のため ^ へ割当。リテラル ^ は z^）
      jj    = 'escape',      -- jj で skkeleton を無効化（j 単独は AZIK の じ行に使用済みのため衝突しない）
    })

    -- ▼候補表示中（henkan ステート）のキー再割り当て。
    -- これらは kanatable ではなく本体の henkan キーマップに定義された関数キーで、
    -- 候補が表示されている最中だけ発火する。デフォルトでは x=前候補・X=辞書パージ。
    -- AZIK は し行を x で打つ（xa→しゃ 等）ため、候補表示中の x がかな入力と衝突する。
    -- x / X を解除して候補表示中も x を AZIK 入力へ開放し（解除後は確定→新規かな入力に回る）、
    -- 前候補へ戻る操作だけ @ へ退避する。退避先に @ を選んだ理由:
    --   1. skkeleton の転送キー既定リスト（autoload/skkeleton.vim の get_default_mapped_keys）に
    --      含まれるため、register_keymap した割り当てが実際に届く（<C-p> 等リスト外のキーは
    --      raw キーが denops に渡らず、ネイティブの ^P 補完に素通りしてしまう）。
    --   2. AZIK かなテーブルで未使用。日本語キーボードで押しやすく、変換直後に @ を打つことは稀。
    --   3. ▽ 入力中は未登録のまま＝通常どおり @ が入力されるだけでゴミにならない（▼ のときだけ前候補）。
    -- パージ（X）は使わないため退避せず解除のみ。func_name を空文字にすると本体側が割り当てを削除する。
    vim.fn['skkeleton#register_keymap']('henkan', 'x', '')                 -- 前候補（x）を解除 → AZIK し行入力へ
    vim.fn['skkeleton#register_keymap']('henkan', 'X', '')                 -- 辞書パージ（X）を解除
    vim.fn['skkeleton#register_keymap']('henkan', '@', 'henkanBackward')   -- 前候補へ戻るを @ へ退避

    -- mini.pairs（自動ペア補完）は global の insert マップだが、skkeleton は有効化中に
    -- 印字記号キーを buffer-local で横取りするため、SKK 有効中は自動ペアが効かない。
    -- これは意図的にそのままにする（横取りリスト g:skkeleton#mapped_keys には手を加えない）。
    -- 括弧キーを mapped_keys から外せば SKK 有効中も mini.pairs が効く反面、変換中（▽/▼）に
    -- 括弧を打つとキーが skkeleton に届かず、skkeleton の「テーブルにない文字は確定して挿入」
    -- 動作（function/input.ts の kanaInput）が発動できない。すると mini.pairs だけが括弧を入れ、
    -- 変換マーカー(▽)が取り残されて消せなくなる（desync）。この実害を避けるため SKK 有効中の
    -- 自動ペアは諦め、自動ペアは SKK 無効時のみ効かせる（運用方針は CLAUDE.md 参照）。

    -- 変換中(▽/▼)の暴発による状態ズレ(desync)対策。
    -- skkeleton は横取りリスト g:skkeleton#mapped_keys に載るキーだけを buffer-local で奪い、
    -- そこに無い Insert 編集系キーはネイティブ Neovim へ素通りする（既定リストは印字 ASCII +
    -- <BS> <C-h> <CR> <Space> <C-q> <C-j> <C-g> <Esc> 等だけ）。変換中に素通りキーが発火すると
    -- バッファのテキストだけが書き換わり、denops 側の skkeleton 内部状態と食い違う。結果 ▽ が
    -- skkeleton の管轄外の「迷子テキスト」になり、C-g(キャンセル)や確定では消せず <BS> 連打を
    -- 強いられる（＝体感上「SKK が無効化された」現象の正体）。
    -- そこで暴発しやすい破壊的な編集キーを横取りリストへ加え、input/henkan の両ステートで
    -- kakutei(確定)に束ねる。変換中に誤爆しても「確定されるだけ」で ▽ が宙に浮かなくなる。
    -- 何も入力していない時の kakutei はカナ副モードを解くだけで SKK 自体は無効化しない（安全）。
    -- 対象は実害が大きく かつ SKK 有効中に使う機会の少ない2キーに限定する:
    -- C-k(ダイグラフ入力) / C-u(行頭まで削除)。
    -- C-w(単語削除)・C-r(レジスタ挿入)は SKK 有効中も使いたいケースが多いため対象から外す
    -- （これらは横取りされず素通りのまま。変換中の暴発は依然 desync を起こし得るが、利便性を優先）。
    local stray_keys = { '<C-k>', '<C-u>' }
    vim.g['skkeleton#mapped_keys'] = vim.list_extend(vim.g['skkeleton#mapped_keys'], stray_keys)
    for _, key in ipairs(stray_keys) do
      vim.fn['skkeleton#register_keymap']('input',  key, 'kakutei')
      vim.fn['skkeleton#register_keymap']('henkan', key, 'kakutei')
    end

    -- グローバル設定
    -- markerHenkan / markerHenkanSelect（デフォルト ▽ / ▼）はバッファへ挿入される「実文字」で、
    -- desync（内部状態とバッファのズレ）が起きた瞬間に消せない残骸として物質化する実害があった
    -- （abbrev 中のネイティブ補完暴発などが引き金）。skkeleton 本体でマーカーは表示文字列の
    -- 連結にのみ使われ状態遷移に関与しない（denops/skkeleton/state.ts）ため、空文字にして
    -- 挿入自体を断つ。desync そのものは起き得るが、バッファが汚れる症状クラスごと消える。
    -- 変換中の視覚表示は skkeleton-henkan-highlight（後述のハイライト定義）で代替する。
    vim.fn['skkeleton#config']({
      globalDictionaries = { '~/.skk/SKK-JISYO.L' },                   -- SKK 辞書ファイル
      eggLikeNewline     = true,                                        -- 変換確定後に改行しない（egg ライク）
      kanaTable          = 'azik',                                      -- 上で登録した AZIK テーブルを使用
      sources            = { 'skk_dictionary', 'google_japanese_input' }, -- SKK 辞書 + Google 変換を併用
      keepState          = true,                                          -- Insert モードを抜けても IME 有効状態を維持
      markerHenkan       = '',                                            -- ▽ を挿入しない（ハイライトで代替）
      markerHenkanSelect = '',                                            -- ▼ を挿入しない（ハイライトで代替）
    })
  end,
})

-- 変換領域ハイライト（skkeleton-henkan-highlight 用）
-- プラグインは User skkeleton-handled イベントごとに g:skkeleton#state（phase / henkanFeed）を
-- 参照し、カーソル位置から領域を逆算して extmark で着色する（バッファ内のマーカー文字は
-- 検索しないため、マーカー空文字化と両立する）。
-- 注意: プラグイン側に hlexists() ガードがあり、下記グループが未定義だとエラーも出さず
-- 何もしない。この定義が事実上の有効化スイッチになっている。
-- ▽相当（読み入力中）は下線のみ、▼相当（候補選択中）は下線+反転で区別する。
-- 色を持たせず属性だけにするのは、colorscheme（minischeme）の配色を壊さないため。
local function set_henkan_hl()
  vim.api.nvim_set_hl(0, 'SkkeletonHenkan',       { underline = true })
  vim.api.nvim_set_hl(0, 'SkkeletonHenkanSelect', { underline = true, reverse = true })
end

-- colorscheme 再適用（draft_skk.md の BufLeave での再読み込み含む）で消えるため当て直す
vim.api.nvim_create_autocmd('ColorScheme', {
  group    = vim.api.nvim_create_augroup('SkkeletonHenkanHl', { clear = true }),
  callback = set_henkan_hl,
})

-- 起動時の colorscheme は既に適用済みのため、ここで一度明示的に当てておく
set_henkan_hl()

-- モード・ステート表示（skkeleton-state-popup 用）
-- カーソル直下のフロート窓に現在の入力モード（あ/ア/ｶﾅ/Ａ/_A）と変換ステート（▽▽/▼▼/ab）を
-- 表示する。マーカーレス運用（markerHenkan 空文字化）では /（abbrev）や ;（変換ポイント）を
-- 押した直後に画面変化が無い（ハイライトは henkanFeed が空だと出ない）ため、その即時
-- フィードバックをバッファ外の popup で補う。ラベル・表示位置は README の Neovim 例に準拠
--（latin のみ短縮、下記コメント参照）。
--
-- 先に skkeleton#is_enabled() を一度呼ぶのは autoload/skkeleton.vim の強制ロードのため。
-- popup は InsertEnter 等で g:skkeleton#mode / g:skkeleton#state を参照するが、これらは
-- skkeleton の autoload 先頭で初期化されるので、未ロードのまま Insert に入ると
-- 未定義変数エラーになる（autoload は初回の関数呼び出しまで読まれない）。
vim.fn['skkeleton#is_enabled']()

vim.fn['skkeleton_state_popup#config']({
  labels = {
    ['input']           = { hira = 'あ',  kata = 'ア',  hankata = 'ｶﾅ',  zenkaku = 'Ａ' },
    ['input:okurinasi'] = { hira = '▽▽', kata = '▽▽', hankata = '▽▽', abbrev = 'ab' },
    ['input:okuriari']  = { hira = '▽▽', kata = '▽▽', hankata = '▽▽' },
    ['henkan']          = { hira = '▼▼', kata = '▼▼', hankata = '▼▼', abbrev = 'ab' },
    -- README 例は '\_A'（バックスラッシュ込み3文字）だが、冗長なため 2 文字に短縮
    latin = '_A',
  },
  opts = { relative = 'cursor', col = 0, row = 1, anchor = 'NW', style = 'minimal' },
})
-- README の run() は enable() の別名（funcref 変数）で vim.fn からは解決できないため実関数を呼ぶ
vim.fn['skkeleton_state_popup#enable']()

-- <C-j> で有効化、<C-l> で無効化（トグルではなくステートレスに操作する）
vim.keymap.set('i', '<C-j>', '<Plug>(skkeleton-enable)',  { desc = 'skkeleton: IME 有効化' })
vim.keymap.set('c', '<C-j>', '<Plug>(skkeleton-enable)',  { desc = 'skkeleton: IME 有効化' })
vim.keymap.set('i', '<C-l>', '<Plug>(skkeleton-disable)', { desc = 'skkeleton: IME 無効化' })
vim.keymap.set('c', '<C-l>', '<Plug>(skkeleton-disable)', { desc = 'skkeleton: IME 無効化' })
