if is_darwin; then
	export ANDROID_HOME=~/android-sdks/
	export ANDROID_NDK_ROOT=~/android-ndk-r10d/
fi

path=(
	$ANDROID_HOME/tools(N-/)
	$ANDROID_HOME/platform-tools(N-/)
	# $ANDROID_HOME/build-tools/19.1.0(N-/)
	$ANDROID_HOME/build-tools/*(N-/)
	# $HOME/android-ndk-*(N-/)
	$ANDROID_NDK_ROOT(N-/)
	$path
)

if type ccache > /dev/null 2>&1; then
	export USE_CCACHE=1
	export CCACHE_DIR=$XDG_CACHE_HOME/ccache
	export NDK_CCACHE=`which ccache`
fi

if type adb.exe > /dev/null 2>&1; then
	alias adb=adb.exe
fi
if type ndk-stack.exe > /dev/null 2>&1; then
	alias ndk-stack=ndk-stack.exe
fi
