oculus.debugtool() {
	if (( ${_platforms[(I)windows]} )); then
		local path="`echo ${^path}/../oculus-diagnostics/OculusDebugTool.exe(N)`"
		$path >/dev/null 2>&1 &
	fi
}