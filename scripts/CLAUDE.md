# scripts

詳細は `README.md` を参照。

## 規約

- shebang 行必須
- 実行権限を付与する（`chmod +x`）
- 同名システムコマンドをラップする場合、`command <cmd>` や絶対パスで再帰呼び出しを避ける
- WSL 専用スクリプトは `scripts/wsl/` に配置
