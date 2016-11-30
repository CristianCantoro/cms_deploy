#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# import variables
source '/tmp/provision/setup_cms/envvars.sh'

# install vim and plugins
cd "$PROVISION_DIR" && \
    cp -r ./nvim/.vimrc "$HOME" && \
    mkdir -p "$HOME/.vim/bundle/" && \
    cd "$HOME/.vim/" && ln -s '../.vimrc' && \
    ln -s '../.vimrc' 'init.vim'
echo ".vimrc installed"

git clone 'https://github.com/VundleVim/Vundle.vim.git' \
			"$HOME/.vim/bundle/Vundle.vim"
nvim --headless +PluginInstall +qall 2>/dev/null
echo "Vundle.vim and plugins installed"

# install tmux and config
cd "$PROVISION_DIR" && \
    cp -r ./tmux/.tmux.conf "$HOME" && \
    cp -r ./tmux/.tmux "$HOME"
echo "tmux configs installed"

exit 0
