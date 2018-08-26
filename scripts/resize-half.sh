#!/bin/sh

_resize() {
	mkdir -p `dirname $2`
	width=`sips -g pixelWidth "$1" | grep pixelWidth | awk '{print $2}'`
	sips --resampleWidth $((width/2)) "$1" --out "`echo "$2" | sed -e "s/\/\//\//g"`"
}

# export -f _resize
# \ls $1 | xargs -I@ sh -c "_resize '$1/@' '$2/@'"

for src in $*; do
	_resize $src $src
done
