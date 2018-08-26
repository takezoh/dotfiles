#!/bin/sh

set -x

input=$1
bundle_identifier=$2
provision=$3
codesign="$4"
entitlements=$5
output=`basename ${input%.*}`.ipa
workdir=${output%.*}.payload

rm -rf $workdir
mkdir $workdir

case "$input" in
*\.ipa)
	cp $input $workdir
	(cd $workdir && unzip -q $output)
	rm $workdir/$output
	;;
*\.app)
	mkdir $workdir/Payload
	cp -r $input $workdir/Payload
	;;
*)
	exit 1
	;;
esac

app=`ls -d $workdir/Payload/*.app`

rm -r $app/_CodeSignature
cp $provision $app/embedded.mobileprovision
plutil -replace CFBundleIdentifier -string $bundle_identifier $app/Info.plist

codesign --force --sign "$codesign" --entitlements $entitlements --timestamp=none $app
(cd $workdir && zip -qr $output Payload)
