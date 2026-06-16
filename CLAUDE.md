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
| `mini.nvim` | `mini.trailspace`（末尾空白）+ `mini.sessions`（セッション管理）+ `mini.pick`（ファジーファインダー）+ `mini.jump`（f/t/F/T 行跨ぎ化） |
| `denops.vim` | Deno ランタイム（skkeleton の依存） |
| `skkeleton` | SKK 日本語入力 |
| `vimdoc-ja` | 日本語 Vim ヘルプ |

### セッション管理（mini.sessions）

`nvim/lua/config/session.lua` で設定。以下のユーザーコマンドが定義されている。

- `:SessionWrite <name>` — グローバルセッションを名前付きで保存
- `:SessionRead <name>` — グローバルセッションを読み込み
- `:SessionDelete <name>` — グローバルセッションを削除
- `:SessionSelect` — 一覧から選択して読み込み

起動順の注意: `mini.nvim` は `lazy = false`（autoread が VimEnter 前に必要）、`shada` から `%` を除外（起動時バッファリスト復元と競合）。保存先は mini.sessions 既定 `stdpath('data')/session`（`directory` 非指定）、cwd のローカルセッションは `.gitignore` 済み。各理由の詳細は plugins.lua / options.lua / session.lua のコメント参照。

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
- **▼候補表示中（henkan ステート）の x / X を再割り当て**: `register_keymap` で x / X を解除して AZIK の し行（`xa`→しゃ 等）を候補表示中も打てるようにし、前候補へ戻る操作は `@` へ退避した。退避先に `@` を選んだ理由（skkeleton の転送キーは固定リストに限られ、`<C-p>` 等リスト外キーは素通りする件）は skkeleton.lua のコメント参照。

**AZIK テーブルを変更したら、対応するテストケースを `nvim/skk/test.yaml` に追加する。**

### draft_skk.md 運用

`draft_skk.md` という名前のファイルを日本語下書き用バッファとして使う運用がある。

- `nvim/lua/config/autocmds.lua` — このバッファ滞在中のみ背景を透明化（BufEnter/BufLeave で切り替え）
- `nvim/lua/config/autocmds.lua` — `<Leader>j` で全文をクリップボードへ切り取り（**バッファローカル**。誤爆防止のためこのバッファ限定）

### ステータスライン（未保存バッファの表示）

未保存バッファは statusline の未保存フラグ `%m`（`[+]`）**だけ**を着色して示す非破壊方式（旧 mini.tabline 方式は廃止）。`laststatus = 2` でウィンドウ個別に表示する。実装の詳細（`%#StatusLineModified#` で囲む着色・`Title` への link・`ColorScheme` での当て直し・draft_skk.md 滞在中の透明化）は options.lua / autocmds.lua のコメント参照。

### 基本キーマップ

リーダーキーはスペース（`init.lua` で `<Leader>` 使用箇所より前に定義）。各マッピングの意図・注意は keymaps.lua のコメント参照。

- `jj` — インサートで Esc / コマンドラインで入力中止
- `<Leader>y` — 全文をクリップボードへヤンク（`:%y`）
- `<Leader>s` — `:SessionSelect`
- `<Leader>f` — `:Pick buffers`
- `h` / `l` — 行頭/行末で行を跨ぐ（`whichwrap` に `h,l` を追加）
- `f`/`t`/`F`/`T`・`;`・`,` — `mini.jump` で行跨ぎ化（`,` の逆方向は keymaps.lua で自作補完）

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
