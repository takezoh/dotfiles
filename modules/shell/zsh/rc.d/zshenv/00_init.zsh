## Environment variable configuration
#
umask 022

# LANG
#
# export LANG=ja_JP.UTF-8
export LC_TIME=C
case ${UID} in
0)
    # LANG=C
		LC_All=C
    ;;
esac


