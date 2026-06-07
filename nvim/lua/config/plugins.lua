-- ============================================================
-- プラグイン定義 (lazy.nvim)
-- ============================================================
-- このファイルはlazy.nvimがrequire('config.plugins')で一括読み込みする。
-- 各エントリにGitHubのURLをコメントとして記載し、一次情報に素早くアクセスできるようにする。

return {

  -- -------------------------------------------------------
  -- ドキュメント
  -- -------------------------------------------------------

  -- https://github.com/vim-jp/vimdoc-ja
  -- Vimの日本語ヘルプ（:h で日本語ドキュメントを参照可能）
  { 'vim-jp/vimdoc-ja' },

  -- -------------------------------------------------------
  -- ユーティリティ
  -- -------------------------------------------------------

  -- https://github.com/echasnovski/mini.nvim
  -- 軽量モジュール群。ここではtrailspace（末尾空白の可視化・削除）を有効化
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.trailspace').setup()
      -- セッション管理：終了時に自動保存、起動時は手動で読み込む
      require('mini.sessions').setup({
        autowrite = true,
        directory  = vim.fn.stdpath('data') .. '/sessions',
        file       = '',
      })
    end,
  },

  { 'vim-denops/denops.vim' },
{ 'vim-skk/skkeleton' },

}
