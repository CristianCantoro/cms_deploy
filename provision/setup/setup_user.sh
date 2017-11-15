#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# import variables
source '/tmp/provision/setup_cms/envvars.sh'

THE_USER_HOME="$CMS_USER_HOME"

# install vim and plugins
cp -r "$PROVISION_DIR/nvim/.vimrc" "$THE_USER_HOME"
mkdir -p "$THE_USER_HOME/.vim/bundle/"
[[ ! -L "$THE_USER_HOME/.vim/.vimrc" ]] && \
  cd "$THE_USER_HOME/.vim/" && ln -s '../.vimrc'
[[ ! -L "$THE_USER_HOME/.vim/init.vim" ]] && \
  cd "$THE_USER_HOME/.vim/" && ln -s '../.vimrc' 'init.vim'
echo ".vimrc installed"

[[ ! -d "$THE_USER_HOME/.vim/bundle/Vundle.vim" ]] && \
  git clone 'https://github.com/VundleVim/Vundle.vim.git' \
            "$THE_USER_HOME/.vim/bundle/Vundle.vim"
nvim --headless +PluginInstall +qall 2>/dev/null
echo "Vundle.vim and plugins installed"

# install tmux and config
cp -r "$PROVISION_DIR/tmux/.tmux.conf" "$THE_USER_HOME"
[[ ! -d "$THE_USER_HOME/.tmux" ]] && \
	cp -r "$PROVISION_DIR/tmux/.tmux" "$THE_USER_HOME"
echo "tmux configs installed"

exit 0
