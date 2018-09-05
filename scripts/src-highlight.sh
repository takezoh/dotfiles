#! /bin/bash

style="--style-css-file=sh_darkblue.css"

for source in "$@"; do
    case $source in
		*ChangeLog|*changelog)
			source-highlight --failsafe -f esc --lang-def=changelog.lang $style -i "$source" ;;
		*Makefile|*makefile)
			source-highlight --failsafe -f esc --lang-def=makefile.lang $style -i "$source" ;;
		*.tar|*.tgz|*.gz|*.bz2|*.xz)
			lesspipe "$source" ;;
		*)
			if `file --mime $source | grep "charset=binary"`; then
				echo "Cannot be highlighing because this file is a binary."
				exit 1
			fi
			# source-highlight --failsafe --infer-lang -f esc256 $style -i "$source"
			# pygmentize -f terminal256 -O style=native -g "$source"
			pygmentize -f terminal256 -O style=zenburn -g "$source"
			# pygmentize -f terminal256 -O style=molokai -g "$source"
			# pygmentize -f terminal256 -O style=jellybeans -g "$source"
			# pygmentize -f terminal256 -O style=blackdust -g "$source"
			# pygmentize -f terminal256 -O style=bensday -g "$source"
			;;
    esac
done
