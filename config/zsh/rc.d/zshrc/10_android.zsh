if (( ${_platforms[(I)darwin]} )); then
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

jar.rev() {
	local jar=$1
	local dir=`echo $jar | sed -e 's/\.jar$//'`
	mkdir $dir
	cp $jar $dir
	(
		cd $dir
		unzip $jar
		# jad -s java -r **/*.class
		jad -s java -r `find . -name "*.class"`
		find . -name "*.class" | xargs rm
	)
	rm $dir/$jar
}

apk.rev() {
	local apk=$1
	local dir=`echo $apk | sed -e 's/\.apk$//'`
	mkdir $dir
	cp $apk $dir
	(
		cd $dir
		unzip $apk
		jadx classes.dex
		# if type dex2jar >/dev/null 2>&1; then
		# 	dex2jar classes.dex
		# elif type d2j-dex2jar >/dev/null 2>&1; then
		# 	d2j-dex2jar classes.dex
		# fi
		# mv classes-dex2jar.jar classes.jar.jar
		# jar.rev classes.jar.jar
		# rm -f classes.jar.jar
	)
	# rm $dir/classes.dex
	rm $dir/$apk
}
