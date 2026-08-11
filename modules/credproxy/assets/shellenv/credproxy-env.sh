# credproxy → 親 env への鍵供給 (change-20260811-credproxy-sandbox-exit-gate)。
#
# login/interactive shell 起動時 (sandbox の外) に broker の env route をすべて解決し、
# export する。これにより Claude Code などの子プロセスが親 env として鍵を継承し、
# sandbox 内で走る consumer (grok.py 等) が env から鍵を読める。
#
# **鍵が増えてもこの file は編集しない。** 追加作業は broker 側の ROUTE_ENV 1 行だけ。
# `credproxy env` が route 一覧を broker から取得して全 env route をまとめて出す。
#
# broker 未起動 / socket 不在 / 鍵未登録のいずれでも `credproxy env` は何も出力せず
# exit 0 するので、shell の起動を壊さない (consumer 側は typed 失敗で理由を出す)。
#
# 機密性の位置づけ: この経路は鍵を親 env に置くので、sandbox 内の consumer = LLM から
# 読める。これは全 host 共通の性質 (sandbox 内からは broker socket に届かないため、
# consumer が鍵を持つ以外の選択肢がない)。Claude host では settings の
# sandbox.credentials mask が上乗せされ、sandboxed process には sentinel だけが見える。
# mask はこの file にも broker にも変更を要求しない。

if command -v credproxy >/dev/null 2>&1; then
	_cpx_token="${CREDPROXY_TOKEN_FILE:-$HOME/.config/credproxyd/token}"
	if [ -f "$_cpx_token" ]; then
		eval "$(credproxy env --token-file "$_cpx_token" 2>/dev/null)"
	else
		eval "$(credproxy env 2>/dev/null)"
	fi
	unset _cpx_token
fi
