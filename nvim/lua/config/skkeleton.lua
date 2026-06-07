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

    -- グローバル設定
    vim.fn['skkeleton#config']({
      globalDictionaries = { '~/.skk/SKK-JISYO.L' }, -- SKK 辞書ファイル
      eggLikeNewline     = true,                      -- 変換確定後に改行しない（egg ライク）
      kanaTable          = 'azik',                    -- 上で登録した AZIK テーブルを使用
    })
  end,
})

-- Insert / Command モードで <C-j> により IME のオン・オフをトグルする
vim.keymap.set('i', '<C-j>', '<Plug>(skkeleton-toggle)', { desc = 'skkeleton: IME トグル' })
vim.keymap.set('c', '<C-j>', '<Plug>(skkeleton-toggle)', { desc = 'skkeleton: IME トグル' })
