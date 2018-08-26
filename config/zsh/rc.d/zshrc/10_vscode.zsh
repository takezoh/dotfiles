if ! type code >/dev/null 2>&1; then
	if (( ${_platforms[(I)windows]} )); then
		alias code="/mnt/c/Program Files/Microsoft VS Code/Code.exe"
	elif (( ${_platform[(I)darwin]})); then
		alias code="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
	fi
fi
