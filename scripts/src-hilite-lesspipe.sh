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
        *) source-highlight --failsafe --infer-lang -f esc $style -i "$source" ;;
    esac
done
