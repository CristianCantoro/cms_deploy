#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# import variables
source '/tmp/provision/setup_cms/envvars.sh'

# install vim and plugins
cp -r "$PROVISION_DIR/nvim/.vimrc" "$CMS_USER_HOME"
mkdir -p "$CMS_USER_HOME/.vim/bundle/"
[[ ! -L "$CMS_USER_HOME/.vim/.vimrc" ]] && \
  cd "$CMS_USER_HOME/.vim/" && ln -s '../.vimrc'
[[ ! -L "$CMS_USER_HOME/.vim/init.vim" ]] && \
  cd "$CMS_USER_HOME/.vim/" && ln -s '../.vimrc' 'init.vim'
echo ".vimrc installed"

[[ ! -d "$CMS_USER_HOME/.vim/bundle/Vundle.vim" ]] && \
  git clone 'https://github.com/VundleVim/Vundle.vim.git' \
            "$CMS_USER_HOME/.vim/bundle/Vundle.vim"
nvim --headless +PluginInstall +qall 2>/dev/null
echo "Vundle.vim and plugins installed"

# install tmux and config
cp -r "$PROVISION_DIR/tmux/.tmux.conf" "$CMS_USER_HOME"
[[ ! -d "$CMS_USER_HOME/.tmux" ]] && \
	cp -r "$PROVISION_DIR/tmux/.tmux" "$CMS_USER_HOME"
echo "tmux configs installed"

exit 0
