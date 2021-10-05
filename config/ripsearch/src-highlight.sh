#! /bin/bash

style="--style-css-file=sh_darkblue.css"

source=$1
head=$2
tail=$3

case $source in
*ChangeLog|*changelog)
	source-highlight --failsafe -f esc --lang-def=changelog.lang $style -i "$source" | tail -n $tail | head -n $head ;;
*Makefile|*makefile)
	source-highlight --failsafe -f esc --lang-def=makefile.lang $style -i "$source" | tail -n $tail | head -n $head ;;
*.tar|*.tgz|*.gz|*.bz2|*.xz)
	lesspipe "$source" ;;
# *.cs)
*)
	pygmentize -f terminal256 -O style=zenburn -g "$source" | head -n $tail | tail -n $(($tail-0)) ;;
# *)
# 	if `file --mime $source | grep "charset=binary"`; then
# 		echo "Cannot be highlighing because this file is a binary."
# 		exit 1
# 	fi
# 	exec bat --style=plain --theme="zenburn" --color=always --unbuffered --line-range="$head:$tail" "$source"
# 	;;
esac
