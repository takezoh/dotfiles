#!/usr/bin/env bash
# Build a devcontainer image, tagging each intermediate stage for cache visibility.
#
# Stages tagged:  <name>:base  <name>:apt  <name>:brew  <name>:install
# Final image:    <name>:setup  <name>:latest
#
# Named intermediate images survive docker image prune and serve as --cache-from
# sources on the next build, so slow stages (brew, install) are not re-run.
#
# Reads:
#   - <workspace>/devcontainer.json
#   - build.name  (preferred — roost extension)
#   - image       (fallback — no build needed; just verifies tag is set)
#
# Usage:
#   ~/.devcontainer/build.sh                       # build cwd
#   ~/.devcontainer/build.sh ~/code/myproject      # build given workspace
#   ~/.devcontainer/build.sh -- --no-cache         # extra args forwarded to docker build

set -euo pipefail

workspace="."
extra_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --) shift; extra_args=("$@"); break ;;
    -*)
      echo "build.sh: unknown flag: $1" >&2
      exit 2
      ;;
    *)
      workspace="$1"
      shift
      ;;
  esac
done

workspace="$(cd "$workspace" && pwd)"
config="$workspace/devcontainer.json"
if [[ ! -f "$config" ]]; then
  echo "build.sh: not found: $config" >&2
  exit 1
fi

# Strip // and /* */ comments so jq can parse JSONC.
strip_jsonc() {
  sed -E -e 's://[^"]*$::g' "$1" \
    | awk 'BEGIN{c=0} {
        line=$0
        out=""
        i=1
        while (i <= length(line)) {
          two=substr(line,i,2)
          if (c==0 && two=="/*") { c=1; i+=2; continue }
          if (c==1 && two=="*/") { c=0; i+=2; continue }
          if (c==0) out = out substr(line,i,1)
          i++
        }
        if (c==0) print out
      }'
}

json="$(strip_jsonc "$config")"

name="$(echo "$json" | jq -er '.build.name // .image // empty')" || true
if [[ -z "${name:-}" ]]; then
  echo "build.sh: $config has neither build.name nor image" >&2
  exit 1
fi

# image: alone means a pre-built image was specified — nothing for us to build.
has_build="$(echo "$json" | jq -r 'has("build")')"
if [[ "$has_build" != "true" ]]; then
  echo "build.sh: $config declares image=$name (no build:); nothing to build."
  echo "build.sh: ensure the image exists locally (docker pull $name) and exit."
  exit 0
fi

# base name without tag (e.g. "dev:latest" → "dev")
base="${name%%:*}"

# context: 置換後に絶対パス化する。
#   ${localEnv:VAR}   → $VAR
#   ${localScript:PATH} → スクリプト実パスのディレクトリから PATH を解決
#                         (build.sh は modules/devcontainer/ に存在するため
#                          "../.." で dotfiles ルートを指せる)
_script_real="$(readlink -f "${BASH_SOURCE[0]}")"
_script_dir="$(dirname "$_script_real")"
raw_context="$(echo "$json" | jq -r '.build.context // "."')"
context="${raw_context/\$\{localEnv:HOME\}/$HOME}"
if [[ "$context" =~ ^\$\{localScript:(.*)\}$ ]]; then
  context="$(cd "$_script_dir/${BASH_REMATCH[1]}" && pwd -P)"
elif [[ "$context" != /* ]]; then
  context="$workspace/$context"
fi

dockerfile="$(echo "$json" | jq -r '.build.dockerfile // "Dockerfile"')"
if [[ "$dockerfile" != /* ]]; then
  dockerfile="$workspace/$dockerfile"
fi

# skills: dotfiles 同階層の別リポ。setup ステージの `COPY --from=skills` 用に
# named build context として渡す。不在なら空ディレクトリを渡し COPY を空に保つ
# （agent-skills が中身を見つけずスキップ＝dotfiles の「無ければスキップ」哲学に一致）。
#
# 実体位置は呼び出し環境で変わる（ホスト/サンドボックス等）。固有パスを埋め込まず、
# build.sh が持つ変数から導いた候補を優先順に探索し最初に存在したものを使う。
#   1. $DOTFILES_SKILLS_DIR  明示オーバーライド（環境固有パスは設定側で注入）
#   2. dotfiles 同階層        build.sh 実体(_script_dir)→dotfiles ルート→その隣
#   3. workspace 直下         ビルド対象 workspace の中の skills
#   4. build context の親      従来ヒューリスティック（最後のフォールバック）
_dotfiles_root="$(cd "$_script_dir/../.." && pwd -P)"
skills_candidates=(
  ${DOTFILES_SKILLS_DIR:+"$DOTFILES_SKILLS_DIR"}
  "$(cd "$_dotfiles_root/.." && pwd -P)/skills"
  "$workspace/skills"
  "$(cd "$context/.." && pwd -P)/skills"
)

skills_ctx=""
for _cand in "${skills_candidates[@]}"; do
  if [[ -d "$_cand" ]]; then
    skills_ctx="$(cd "$_cand" && pwd -P)"
    break
  fi
done

build_contexts=()
if [[ -n "$skills_ctx" ]]; then
  build_contexts+=(--build-context "skills=$skills_ctx")
else
  _empty_skills="$(mktemp -d)"
  trap 'rm -rf "$_empty_skills"' EXIT
  build_contexts+=(--build-context "skills=$_empty_skills")
  echo "build.sh: warn: skills not found (tried: ${skills_candidates[*]}) — building without skills" >&2
  skills_ctx="(none: empty context)"
fi

echo "build.sh: building $workspace"
echo "build.sh:   image    = $name  (base: $base)"
echo "build.sh:   context  = $context"
echo "build.sh:   skills   = $skills_ctx"
echo "build.sh:   file     = $dockerfile"

# Intermediate stages — built and tagged so they survive docker image prune.
# --cache-from reuses the named image when inline layer cache was pruned.
intermediate_stages=(base apt brew install)

for stage in "${intermediate_stages[@]}"; do
  echo ""
  echo "build.sh: ── stage: $stage → $base:$stage"
  docker build \
    --target "$stage" \
    --tag    "$base:$stage" \
    --cache-from "$base:$stage" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --file   "$dockerfile" \
    "${extra_args[@]}" \
    "$context"
done

# Final stage: tagged as both <base>:setup and <base>:latest (= build.name)
# skills は setup ステージでのみ COPY されるため、named context は final ビルドにのみ渡す。
echo ""
echo "build.sh: ── stage: setup → $base:setup  $name"
docker build \
  --tag "$base:setup" \
  --tag "$name" \
  --cache-from "$base:setup" \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  "${build_contexts[@]}" \
  --file "$dockerfile" \
  "${extra_args[@]}" \
  "$context"

echo ""
echo "build.sh: done."
docker images --filter "reference=$base" --format "  {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
