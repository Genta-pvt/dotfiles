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

    -- mini.pairs（自動ペア補完）との競合回避。
    -- skkeleton は有効化のたびに印字記号キーを buffer-local + <nowait> の insert マップで
    -- 横取りし、global で張られた mini.pairs のマップを覆ってしまう（buffer-local + <nowait>
    -- が global より優先されるため）。結果、skk 有効中は括弧・引用符の自動ペアが一切効かない。
    -- そこで、かな割り当てのない ( ) { } " ' ` の7種だけを横取りリスト g:skkeleton#mapped_keys
    -- から除外し、global の mini.pairs に渡す（skk 有効中もこれらは自動ペア化される）。
    -- [ ] は外さない: 単打 [→「 / ]→」、派生 x[→半角[ / z[→『 等で使用中であり、外すと
    --   これらキー押下が skkeleton に届かず日本語入力が壊れる（継続入力の途中キーも同じ
    --   マップ経由で受け取るため、x の継続待ち中に [ を奪われると pending が宙に浮く）。
    -- <BS> <CR> も外さない: 外すと変換確定・かなバッファ削除という SKK の根幹が機能しなくなる。
    --   かなモード中のペア内 BS 両側削除・Enter 展開は諦める（skk 無効時は mini.pairs が効く）。
    local pair_keys = { ['(']=true, [')']=true, ['{']=true, ['}']=true, ['"']=true, ["'"]=true, ['`']=true }
    local mapped = vim.g['skkeleton#mapped_keys'] or {}
    vim.g['skkeleton#mapped_keys'] = vim.tbl_filter(function(k) return not pair_keys[k] end, mapped)

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
    -- 対象は実害の大きい4キーに限定する: C-w(単語削除) / C-u(行頭まで削除) / C-k(ダイグラフ) /
    -- C-r(レジスタ挿入)。代償として SKK 有効中はこの4キーのネイティブ動作が確定に化ける
    -- （単語削除等をしたい時は <C-l> で一旦 SKK を無効化する）。
    local stray_keys = { '<C-w>', '<C-u>', '<C-k>', '<C-r>' }
    vim.g['skkeleton#mapped_keys'] = vim.list_extend(vim.g['skkeleton#mapped_keys'], stray_keys)
    for _, key in ipairs(stray_keys) do
      vim.fn['skkeleton#register_keymap']('input',  key, 'kakutei')
      vim.fn['skkeleton#register_keymap']('henkan', key, 'kakutei')
    end

    -- グローバル設定
    vim.fn['skkeleton#config']({
      globalDictionaries = { '~/.skk/SKK-JISYO.L' },                   -- SKK 辞書ファイル
      eggLikeNewline     = true,                                        -- 変換確定後に改行しない（egg ライク）
      kanaTable          = 'azik',                                      -- 上で登録した AZIK テーブルを使用
      sources            = { 'skk_dictionary', 'google_japanese_input' }, -- SKK 辞書 + Google 変換を併用
      keepState          = true,                                          -- Insert モードを抜けても IME 有効状態を維持
    })
  end,
})

-- <C-j> で有効化、<C-l> で無効化（トグルではなくステートレスに操作する）
vim.keymap.set('i', '<C-j>', '<Plug>(skkeleton-enable)',  { desc = 'skkeleton: IME 有効化' })
vim.keymap.set('c', '<C-j>', '<Plug>(skkeleton-enable)',  { desc = 'skkeleton: IME 有効化' })
vim.keymap.set('i', '<C-l>', '<Plug>(skkeleton-disable)', { desc = 'skkeleton: IME 無効化' })
vim.keymap.set('c', '<C-l>', '<Plug>(skkeleton-disable)', { desc = 'skkeleton: IME 無効化' })
