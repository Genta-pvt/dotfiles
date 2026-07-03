-- ============================================================
-- プラグイン定義 (lazy.nvim)
-- ============================================================
-- lazy.nvim が require('config.plugins') で一括ロードする。
-- 各エントリに GitHub URL を記載し、一次情報へ素早くアクセスできるようにする。

return {

  -- -------------------------------------------------------
  -- ドキュメント
  -- -------------------------------------------------------

  -- https://github.com/vim-jp/vimdoc-ja
  -- Vim の日本語ヘルプ（:h で日本語ドキュメントを参照可能）
  { 'vim-jp/vimdoc-ja' },

  -- -------------------------------------------------------
  -- ユーティリティ
  -- -------------------------------------------------------

  -- https://github.com/echasnovski/mini.nvim
  -- 軽量モジュール群。以下を有効化:
  --   mini.trailspace : 末尾空白の可視化・一括削除
  --   mini.sessions   : セッション保存・復元（config.session で設定）
  --   mini.pick       : ファジーファインダー（:Pick コマンドで使用）
  --   mini.jump       : f/t/F/T を行跨ぎ化（; で行跨ぎ repeat。, は keymaps.lua で補完）
  --   mini.pairs      : 括弧・引用符の自動ペア補完（( [ { " ' ` の入力で閉じを自動挿入）
  --   mini.surround   : 囲み（括弧・引用符・タグ）の追加/削除/置換/検索/強調
  --   minischeme      : カラースキーム（options.lua で colorscheme 指定）
  -- 未保存バッファの強調は mini.tabline をやめ、statusline の色で表現する
  -- （画面行を消費せず、ウィンドウ個別に未保存を示せる。options.lua / autocmds.lua 参照）
  {
    'echasnovski/mini.nvim',
    version = false,
    lazy    = false,  -- 起動時に同期ロード（options.lua の colorscheme 'minischeme' が mini.nvim 同梱で、設定適用前にロード済みが必要）
    config = function()
      require('mini.trailspace').setup()
      require('mini.pick').setup()
      -- f/t/F/T を行跨ぎ化（Normal/Visual/operator-pending 対応）。; も行跨ぎ repeat になる。
      -- 逆方向 repeat の , は mini.jump がマップしないため keymaps.lua で別途補う。
      require('mini.jump').setup()
      -- 自動ペア補完。( [ { " ' ` の入力で対応する閉じを自動挿入しカーソルを間に置く。
      -- 閉じ括弧の通り抜け・ペア内 BS の両側削除・ペア内 Enter のインデント展開も有効。
      -- 全角ペア（「」等）は対象外（要望外のため半角のみ。必要時は pairs オプションで追加可）。
      require('mini.pairs').setup()
      -- 囲み操作。デフォルトキー（sa 追加 / sd 削除 / sr 置換 / sf・sF 検索 / sh 強調）を使う。
      -- s 始まりのマップ使用中、素の s（1文字置換）は誤爆防止で <Nop> に潰される（代替は cl）。
      require('mini.surround').setup()
      require('config.session')
    end,
  },

  -- -------------------------------------------------------
  -- markdown 編集支援
  -- -------------------------------------------------------

  -- https://github.com/jakewvincent/mkdnflow.nvim
  -- リスト自動継続・チェックボックストグル・リンク化・見出しレベル操作。
  -- ft='markdown' で遅延ロードし、設定・キーマップは config.markdown に集約する。
  -- 自動マップは無効化し必要分だけ明示登録する方針（理由は config/markdown.lua のコメント参照）。
  {
    'jakewvincent/mkdnflow.nvim',
    ft     = 'markdown',
    config = function()
      require('config.markdown')
    end,
  },

  -- -------------------------------------------------------
  -- 日本語入力（SKK + AZIK）
  -- -------------------------------------------------------

  -- https://github.com/vim-denops/denops.vim
  -- Deno ランタイムブリッジ。skkeleton の動作に必須
  { 'vim-denops/denops.vim' },

  -- https://github.com/vim-skk/skkeleton
  -- SKK 日本語入力エンジン。設定は config.skkeleton で行う
  { 'vim-skk/skkeleton' },

  -- https://github.com/NI57721/skkeleton-henkan-highlight
  -- 変換中（▽/▼ステート）の入力領域を extmark でハイライト表示する。
  -- 変換マーカー文字を空にした運用（config.skkeleton 参照）の視覚的代替。
  -- User skkeleton-handled イベント駆動の軽量 vimscript のため遅延ロード指定は不要
  { 'NI57721/skkeleton-henkan-highlight' },

  -- https://github.com/NI57721/skkeleton-state-popup
  -- SKK の入力モード・変換ステートをカーソル直下のフロート窓に表示する。
  -- マーカーレス運用で失われた「/（abbrev）や ;（変換ポイント）直後の即時フィードバック」を補う。
  -- plugin/ ディレクトリを持たない設計のため、有効化は config.skkeleton 側の
  -- skkeleton_state_popup#config() + enable() 呼び出しで行う（これが公式のセットアップ手順）
  { 'NI57721/skkeleton-state-popup' },

}
