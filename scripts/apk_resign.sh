#!/bin/sh
set -x

apk_path=$1
store_path=$2
store_pass=$3
alias_name=$4
alias_pass=$5

output=`basename ${apk_path}`
workdir=${output%.*}.payload

rm -rf $workdir
mkdir $workdir

cp $apk_path $workdir/$output

(
	cd $workdir

	zip -d $output 'META-INF*'

	jarsigner -verbose \
		-keystore $store_path \
		-storepass $store_pass \
		$output \
		$alias_name \
		-keypass $alias_pass \
		-sigalg SHA1withRSA -digestalg SHA1
)
