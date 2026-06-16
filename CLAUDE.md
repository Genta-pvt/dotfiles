# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

Windows 環境向けのドットファイルリポジトリ。主に Neovim 設定、PowerShell プロファイル、Windows Terminal 設定を管理する。

## 操作上の規約

- `git status`、`git log`、`git diff` の実行は確認不要

## コーディング規約

- **コメントは必ず日本語で書く**（英語コメント不可）
- リファクタリング時もコメントを削除せず、整理・補完する
- **改行コードは LF に統一**する。リポジトリ同梱の `.gitattributes`（`* text=auto eol=lf`）で作業ツリーも含め LF を強制しており、新規ファイルも LF で保存する。CRLF 由来の「中身は同じなのに差分」を防ぐため、`core.autocrlf` に頼らずこの規約で固定する。

## Neovim 設定アーキテクチャ

エントリポイントは `nvim/init.lua`。lazy.nvim を自動インストールし、以下のモジュールを順に読み込む。

```
nvim/init.lua
├── require('lazy').setup('config.plugins')   ← nvim/lua/config/plugins.lua
├── require('config.options')                 ← nvim/lua/config/options.lua
├── require('config.keymaps')                 ← nvim/lua/config/keymaps.lua
├── require('config.autocmds')                ← nvim/lua/config/autocmds.lua
└── require('config.skkeleton')               ← nvim/lua/config/skkeleton.lua
```

`plugins.lua` の `mini.nvim` エントリ内で `require('config.session')` を呼び出す（`lazy = false` で強制早期ロード）。

### プラグイン構成

| プラグイン | 用途 |
|---|---|
| `lazy.nvim` | プラグインマネージャー |
| `mini.nvim` | `mini.trailspace`（末尾空白）+ `mini.sessions`（セッション管理） |
| `denops.vim` | Deno ランタイム（skkeleton の依存） |
| `skkeleton` | SKK 日本語入力 |
| `vimdoc-ja` | 日本語 Vim ヘルプ |

### セッション管理（mini.sessions）

`nvim/lua/config/session.lua` で設定。以下のユーザーコマンドが定義されている。

- `:SessionWrite <name>` — グローバルセッションを名前付きで保存
- `:SessionRead <name>` — グローバルセッションを読み込み
- `:SessionDelete <name>` — グローバルセッションを削除
- `:SessionSelect` — 一覧から選択して読み込み

`mini.nvim` を `lazy = false` にしているのは、`autoread` が VimEnter 前に動作しなければならないため。`shada` の `%` オプションを除外しているのも同じ理由（起動時バッファリストの復元と競合するため）。

グローバルセッションの保存先は mini.sessions のデフォルト `stdpath('data')/session`（単数形・リポジトリ外）。`directory` を明示指定しないのは意図的で、デフォルト運用の環境と保存先を揃えるため。cwd に生成されるローカルセッション（`Session.vim` 等）は `.gitignore` で除外している。

### SKK 日本語入力（skkeleton + AZIK）

- `nvim/lua/config/skkeleton.lua` — グローバル設定、function マッピング、IME キーマップ
- `nvim/lua/config/skkeleton_azik.lua` — AZIK かな変換テーブル（**かなマッピングのみ**）
- `nvim/skk/test.yaml` — AZIK テーブルの手動テストケース（`入力: 期待されるかな` 形式。自動テストランナーはない）

**前提条件**: SKK 辞書ファイルが `~/.skk/SKK-JISYO.L` に存在すること。denops.vim は Deno ランタイムが必要。

キーマップ（`skkeleton.lua`）: `<C-j>` で有効化、`<C-l>` で無効化（トグルではなくステートレス操作）。skkeleton 有効中は `jj` で escape。

AZIK テーブルは `skkeleton-initialize-pre` イベントで `skkeleton#register_kanatable('azik', ...)` により登録される。注意点:

- かなテーブルと function マッピング（`henkanFirst`、`abbrev`、`henkanPoint`、`escape`）は登録箇所が分離している。azik テーブルは `create=true` で空生成されデフォルト rom の function を引き継がないため、必要な function は `skkeleton.lua` 側で明示的に登録する
- `do` が Lua 予約語のためブラケット記法 `['do']` を使用している
- 変換 source は SKK 辞書 + `google_japanese_input` の併用

**AZIK テーブルを変更したら、対応するテストケースを `nvim/skk/test.yaml` に追加する。**

### draft_skk.md 運用

`draft_skk.md` という名前のファイルを日本語下書き用バッファとして使う運用がある。

- `nvim/lua/config/autocmds.lua` — このバッファ滞在中のみ背景を透明化（BufEnter/BufLeave で切り替え）
- `nvim/lua/config/autocmds.lua` — `<Leader>j` で全文をクリップボードへ切り取り（**バッファローカル**。誤爆防止のためこのバッファ限定）

### ステータスライン（未保存バッファの表示）

未保存バッファは、ステータスラインの未保存フラグ `%m`（`[+]`）**だけ**を着色して示す（旧 mini.tabline 方式は廃止）。

- `nvim/lua/config/options.lua` — `laststatus = 2` を明示し、各ウィンドウが個別のステータスラインを持つ。`statusline` は未保存フラグ `%m` を `%#StatusLineModified#…%*` で囲み、`[+]` 部分のみを着色する。`%m` は描画対象ウィンドウのバッファごとに評価されるため、分割中も各ウィンドウが自分の未保存状態を個別に表示する。
- `nvim/lua/config/autocmds.lua` — `StatusLineModified` ハイライトを定義（既存グループ `Title` へ link）。バー本体（`StatusLine`）は塗り替えず、フラグだけに色を足す非破壊方式。`ColorScheme` イベントで当て直すのは、colorscheme 再読み込み（draft_skk.md の透明化解除を含む）で link が初期化されるため。`draft_skk.md` 滞在中は `StatusLineModified` も透明化対象に含め、下書き中は色を出さない。

### 基本キーマップ

リーダーキーはスペース（`init.lua` で `<Leader>` 使用箇所より前に定義）。

- `jj`（インサート）— Esc
- `<Leader>y`（ノーマル、グローバル）— 全文をクリップボードへヤンク（`:%y`、カーソル位置を保持）
- `<Leader>s`（ノーマル、グローバル）— `:SessionSelect`（セッションを選択して読み込み）
- `<Leader>f`（ノーマル、グローバル）— `:Pick buffers`（バッファ一覧から選択）

### シェル設定

`nvim/lua/config/options.lua` で Neovim 内部のシェルを PowerShell に設定済み（`shellpipe`/`shellredir` も UTF-8 出力向けに調整済み）。

## ディレクトリ構成

```
dotfiles/
├── nvim/
│   ├── init.lua                        # エントリポイント
│   ├── lazy-lock.json                  # プラグインバージョンロック
│   ├── skkeleton_init.vim              # (旧設定、現在は skkeleton.lua が主)
│   ├── skk/
│   │   └── test.yaml                   # AZIK かなテーブルの手動テストケース
│   └── lua/config/
│       ├── plugins.lua                 # プラグイン定義
│       ├── options.lua                 # エディタオプション
│       ├── keymaps.lua                 # キーマッピング
│       ├── autocmds.lua                # オートコマンド
│       ├── session.lua                 # mini.sessions 設定
│       ├── skkeleton.lua               # SKK 設定・キーマップ
│       └── skkeleton_azik.lua          # AZIK かなテーブル
├── powershell/
│   └── profile.ps1                     # AWS CLI 補完設定
└── windows-terminal/
    └── settings.json                   # Windows Terminal 設定
```
