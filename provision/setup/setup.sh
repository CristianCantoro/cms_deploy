#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# this script is run as root
source '/tmp/provision/setup_cms/envvars.sh'

function install_oh_my_zsh {

  local change_user="$1"
  local change_user_home="$2"

  # copy zshrc template to .zshrc in user home
  cp "/etc/zsh/newuser.zshrc.recommended" "$change_user_home/.zshrc"
  chown "$change_user:$change_user" "$change_user_home/.zshrc"
  echo "copying zshrc template to $change_user_home/.zshrc"

  # change default shell to zsh
  chsh -s "$(command -v zsh)" "$change_user"
  echo "default shell changed to zsh for user '$change_user'"

  # download install script
  # local omzrepo='https://raw.githubusercontent.com/robbyrussell/oh-my-zsh'
  # curl -fsSL "$omzrepo/master/tools/install.sh" \
  #   -o "$change_user_home/install_ohmyzsh.sh"
  #
  # does not work b/c of the following bug: 
  # * [Ansible hangs trying to install oh-my-zsh]
  #   (https://github.com/ansible/ansible/issues/14492)
  #
  # we copy a modified install script from the provision dir. 
  cp "$PROVISION_DIR/zsh/install_ohmyzsh.sh" \
    "$change_user_home/install_ohmyzsh.sh"
  echo "oh-my-zsh install script saved to" \
       "$change_user_home/install_ohmyzsh.sh"

  # install oh-my-zsh
  if [ ! -d "$change_user_home/.oh-my-zsh" ]; then

    if [ "$change_user" == 'root' ]; then
      sh "$change_user_home/install_ohmyzsh.sh"
    else
      su -c "sh '$change_user_home/install_ohmyzsh.sh'" "$change_user"
    fi

    echo "oh-my-zsh installed for user $change_user"
  else
    echo "oh-my-zsh alredy installed for user $change_user, skipping"
  fi

  # change zsh theme
  cp "$change_user_home/.oh-my-zsh/templates/zshrc.zsh-template" \
    "$change_user_home/.zshrc"
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' \
    "$change_user_home/.zshrc"

  # make sure that .zshrc is owned by user
  chown "$change_user:$change_user" "$change_user_home/.zshrc"

  # remove install script, goodbye
  rm -f "$change_user_home/install_ohmyzsh.sh"

}

# no dialogw or questions
export DEBIAN_FRONTEND=noninteractive

# fix the locales
export LANG="en_US.UTF-8"
export LANGUAGE="en_US"
export LC_CTYPE="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_PAPER="en_US.UTF-8"
export LC_NAME="en_US.UTF-8"
export LC_ADDRESS="en_US.UTF-8"
export LC_TELEPHONE="en_US.UTF-8"
export LC_MEASUREMENT="en_US.UTF-8"
export LC_IDENTIFICATION="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
locale-gen it_IT.UTF-8 en_US.UTF-8 &>/dev/null
dpkg-reconfigure locales &>/dev/null
echo "locales fixed"

# update & upgrade the system
quiet_update && quiet_upgrade
echo "system upgraded"

timedatectl set-timezone 'Europe/Rome'
echo "system timezone set to 'Europe/Rome'"

# base packages
quiet_install linux-virtual
echo "new kernels installed"

quiet_install htop tree lynx colordiff tmux zsh git-core molly-guard \
              ntp ntp-doc ntpdate gpgv2 apt-transport-https \
              ca-certificates software-properties-common
echo "basic packages installed"

add-apt-repository -y ppa:neovim-ppa/unstable
quiet_install
quiet_update && quiet_install neovim
[[ ! -L /usr/bin/neovim ]] && cd /usr/bin && ln -s nvim neovim
echo "neovim installed"

# quiet apt-get autoremove
quiet_autoremove

# zsh for root and CMS_USER
install_oh_my_zsh "$USER" "$HOME"
install_oh_my_zsh "$CMS_USER" "$CMS_USER_HOME"
echo "oh_my_zsh installed"

# zsh for root and CMS_USER
mkdir -p "$HOME/.ssh/"
cat "$PROVISION_DIR/setup/id_rsa.pub" > "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

mkdir -p "$CMS_USER_HOME/.ssh/"
cat "$PROVISION_DIR/setup/id_rsa.pub" > "$CMS_USER_HOME/.ssh/authorized_keys"
chmod 600 "$CMS_USER_HOME/.ssh/authorized_keys"
chown -R "$CMS_USER:$CMS_USER" "$CMS_USER_HOME/.ssh/"
echo "copy ssh key to $CMS_USER_HOME/.ssh/"

exit 0
