#!/bin/bash
rootdir=$(cd `dirname $0` && pwd -P)
sharedir=$HOME/.local/share/pygments_ex
mkdir -p $sharedir/styles
touch $sharedir/styles/__init__.py
cd $sharedir

# Vim Color Scheme Editor "Vivify" [http://bytefluent.com/devify]
for s in `cd $rootdir/../../config/nvim/colors && command ls`; do
	python3 $rootdir/../../external/vim2pygments/vimpygments.py $rootdir/../../config/nvim/colors/$s > styles/${s%%.*}.py
done

# generate setup.py
cat <<EOF | python3 > setup.py
import os

def style_entry_point(f):
	name = f[:-3]
	capitalized_name = '_'.join(x.capitalize() for x in name.split('_'))
	return "{0} = styles.{0}:{1}Style".format(name, capitalized_name)

template = open("$rootdir/setup.template.py", "r").read()
print (template.format(
		lexers="",
		styles="\n".join([style_entry_point(x) for x in os.listdir("styles") if x != '__init__.py'])))
EOF

python3 setup.py install
