cxx-count-include() {
 rg -e "^#include" "$@" | awk -F ':#' '{ print $1 }' | uniq -c | sort -r | head -n 10
}
