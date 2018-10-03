path+=(
	/mnt/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2017/Professional/MSBuild/15.0/Bin(N-/)
	$path
)

if (( ${_platforms[(I)windows]} )); then
	alias devenv="/mnt/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2017/Professional/Common7/IDE/devenv.exe"
	alias code="/mnt/c/Program\ Files/Microsoft\ VS\ Code/Code.exe"
elif (( ${_platform[(I)darwin]})); then
	alias code="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi
