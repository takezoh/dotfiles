_mod_dir=$DOTFILES_DIR/modules

source $_mod_dir/mise/env.sh
source $_mod_dir/rust/env.sh
source $_mod_dir/cli-gcloud/env.sh

export GOPATH=$XDG_DATA_HOME/go

unset _mod_dir
