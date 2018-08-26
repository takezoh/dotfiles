path=(
	$HOME/android-sdks/tools(N-/)
	$HOME/android-sdks/platform-tools(N-/)
	# $HOME/android-sdks/build-tools/19.1.0(N-/)
	$HOME/android-sdks/build-tools/*(N-/)
	$HOME/android-ndk-*(N-/)
	$path
)

export NDK_ROOT=~/android-ndk-r10d/
export ANDROID_HOME=~/android-sdks/

if type ccache > /dev/null 2>&1; then
	export USE_CCACHE=1
	export CCACHE_DIR=$XDG_CACHE_HOME/ccache
	export NDK_CCACHE=`which ccache`
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
		# jad -s java -r `find . -name "*.class"`
		find . -name "*.class" | xargs jad -s java -r
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
		d2j-dex2jar classes.dex
		mv classes-dex2jar.jar classes.jar.jar
		jar.rev classes.jar.jar
		rm -f classes.jar.jar
	)
	# rm $dir/classes.dex
	rm $dir/$apk
}
