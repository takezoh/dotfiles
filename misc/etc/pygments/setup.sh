#!/bin/bash
cd `dirname $0`

# Vim Color Scheme Editor "Vivify" [http://bytefluent.com/devify]
for s in `cd ../../../config/nvim/colors && command ls`; do
	python3 ../../../external/vim2pygments/vimpygments.py ../../../config/nvim/colors/$s > styles/${s%%.*}.py
done

# generate setup.py
cat <<EOF | python3
import os

def style_entry_point(f):
	name = f[:-3]
	capitalized_name = '_'.join(x.capitalize() for x in name.split('_'))
	return "{0} = styles.{0}:{1}Style".format(name, capitalized_name)

open("setup.py", "w").write(
	open("setup.template.py", "r").read().format(
		lexers="",
		styles="\n".join([style_entry_point(x) for x in os.listdir("styles")])))
EOF

sudo -H python3 setup.py install
