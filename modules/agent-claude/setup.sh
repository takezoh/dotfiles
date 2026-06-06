#!/usr/bin/env zsh
# Note: zsh required for ${0:A:h} and yq/jq processing
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"
. "$MODULES_DIR/brew/env.sh"  # yq/jq を PATH に乗せる

log "agent-claude: setup"

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
MANAGED_SETTINGS="$MODULES_DIR/agent-claude/claude/settings.yaml"
CLAUDE_MD_SOURCE="$MODULES_DIR/agent-claude/claude/CLAUDE.md"
MERGE_APPEND="$MODULES_DIR/_lib/merge_append.py"
ROOST_BIN="/workspace/agent-roost/roost"

mkdir -p "$CLAUDE_DIR"

# Symlink CLAUDE.md
ln -sf "$CLAUDE_MD_SOURCE" "$CLAUDE_DIR/CLAUDE.md"
echo "Linked: $CLAUDE_DIR/CLAUDE.md -> $CLAUDE_MD_SOURCE"

# Settings: YAML→JSON 変換し $USERPROFILE 展開
MANAGED_JSON=$(yq eval '.' "$MANAGED_SETTINGS" -o json | jq --arg up "${USERPROFILE:-}" '
    def expand_userprofile:
        walk(
            if type == "string" and test("\\$USERPROFILE") then
                if $up == "" then null
                else gsub("\\$USERPROFILE"; $up) end
            else . end
        )
        | walk(if type == "array" then map(select(. != null)) else . end);
    expand_userprofile
')
UPDATED=$("$MERGE_APPEND" json <(printf '%s' "$MANAGED_JSON") "$SETTINGS")
UPDATED=$(printf '%s\n' "$UPDATED" | jq --slurpfile managed <(printf '%s' "$MANAGED_JSON") '.hooks = (($managed[0].hooks // {}))')
printf '%s\n' "$UPDATED" > "$SETTINGS"
echo "Updated: $SETTINGS"

# ~/.claude.json config
CLAUDE_JSON="$HOME/.claude.json"
MANAGED_CONFIG="$MODULES_DIR/agent-claude/claude/config.yaml"
if [[ -f "$CLAUDE_JSON" ]]; then
	UPDATED_CONFIG=$(yq eval '.' "$MANAGED_CONFIG" -o json | jq 'input * .' - "$CLAUDE_JSON")
	printf '%s\n' "$UPDATED_CONFIG" > "$CLAUDE_JSON"
	echo "Updated: $CLAUDE_JSON"
fi

# /etc/claude-code/managed-settings.json（devcontainer のみ、sudo で配置）
if is_devcontainer; then
	as_root mkdir -p /etc/claude-code
	as_root cp "$MODULES_DIR/agent-claude/claude/managed-settings.json" /etc/claude-code/managed-settings.json
	echo "Installed: /etc/claude-code/managed-settings.json"
fi

# Hooks symlink
for dir in hooks; do
	rm -rf "$CLAUDE_DIR/$dir"
	ln -sfn "$MODULES_DIR/agent-claude/claude/$dir" "$CLAUDE_DIR/$dir"
	echo "Linked: $CLAUDE_DIR/$dir -> $MODULES_DIR/agent-claude/claude/$dir"
done

# statusline.sh symlink
ln -sf "$MODULES_DIR/agent-claude/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
echo "Linked: $CLAUDE_DIR/statusline.sh -> $MODULES_DIR/agent-claude/claude/statusline.sh"

# Plugin marketplaces & plugins（claude が PATH にあるときのみ）
if has_cmd claude; then
	typeset -A MARKETPLACES=(
		[claude-plugins-official]="anthropics/claude-plugins-official"
		[obsidian-skills]="kepano/obsidian-skills"
		[claude-obsidian-marketplace]="AgriciDaniel/claude-obsidian"
	)
	PLUGINS=(
		discord@claude-plugins-official
		obsidian@obsidian-skills
		clangd-lsp@claude-plugins-official
		pyright-lsp@claude-plugins-official
		typescript-lsp@claude-plugins-official
		gopls-lsp@claude-plugins-official
		code-review@claude-plugins-official
		feature-dev@claude-plugins-official
		frontend-design@claude-plugins-official
		code-simplifier@claude-plugins-official
		agent-sdk-dev@claude-plugins-official
		skill-creator@claude-plugins-official
		claude-md-management@claude-plugins-official
		pr-review-toolkit@claude-plugins-official
		security-guidance@claude-plugins-official
		plugin-dev@claude-plugins-official
		slack@claude-plugins-official
		claude-obsidian@claude-obsidian-marketplace
	)

	EXISTING_MP=$(claude plugin marketplace list 2>/dev/null || true)
	for name in "${(@k)MARKETPLACES}"; do
		if printf '%s\n' "$EXISTING_MP" | grep -qE "❯ ${name}\$"; then
			echo "Marketplace exists: $name"
		else
			claude plugin marketplace add "${MARKETPLACES[$name]}"
		fi
	done
	claude plugin marketplace update >/dev/null 2>&1 || true

	EXISTING_PL=$(claude plugin list 2>/dev/null || true)
	for p in "${PLUGINS[@]}"; do
		if printf '%s\n' "$EXISTING_PL" | grep -qE "❯ ${p}\$"; then
			echo "Plugin exists: $p"
		else
			claude plugin install "$p" --scope user \
				|| echo "[warn] plugin install failed: $p (retry: claude plugin install $p --scope user)"
		fi
	done
fi

echo "Done."
