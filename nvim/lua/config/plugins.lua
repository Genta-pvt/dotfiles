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
  --   minischeme      : カラースキーム（options.lua で colorscheme 指定）
  -- 未保存バッファの強調は mini.tabline をやめ、statusline の色で表現する
  -- （画面行を消費せず、ウィンドウ個別に未保存を示せる。options.lua / autocmds.lua 参照）
  {
    'echasnovski/mini.nvim',
    version = false,
    lazy    = false,  -- VimEnter 前に確実にロードする（mini.sessions の autoread 用）
    config = function()
      require('mini.trailspace').setup()
      require('mini.pick').setup()
      -- f/t/F/T を行跨ぎ化（Normal/Visual/operator-pending 対応）。; も行跨ぎ repeat になる。
      -- 逆方向 repeat の , は mini.jump がマップしないため keymaps.lua で別途補う。
      require('mini.jump').setup()
      require('config.session')
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

}
