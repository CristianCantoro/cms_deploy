# encoding: utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

# Read envitionment variable CMS_INSTALL_TEXLIVEFULL to skip installation
# of texlive-full package.
# See:
# https://stackoverflow.com/questions/14124234/
# Custom options don't seem to work with all versions of Vagrant and Ruby.
cms_install_texlivefull=!!ENV['CMS_INSTALL_TEXLIVEFULL']


current_dir = File.dirname(File.expand_path(__FILE__))
cms_config_file = "cms.yml"
cms_config = YAML.load_file(File.join("#{current_dir}",
                                      "provision",
                                      "#{cms_config_file}"))
cms_user = cms_config['CMS']['USER']
cms_usergroup = cms_config['CMS']['USERGROUP']

Vagrant.configure("2") do |config|
  config.vm.define "cms_provision"
  config.vm.define "cms_ansible"

  config.vm.box = "ubuntu/xenial64"

  config.vm.provider "virtualbox" do |vb| 
    # 1GB RAM
    vb.memory = "2048"
  end
  config.vm.hostname = 'cms'
  config.vm.network "private_network", type: "dhcp"

  ############################################################################
  ## Provision for all the machines
  ############################################################################

  ## fix the annoying 'stdin: is not a tty' error
  ## See: https://github.com/mitchellh/vagrant/issues/1673
  config.vm.provision :shell, \
    inline: "cp /vagrant/provision/setup/root_profile /root/.profile"
  ############################################################################

  ############################################################################
  ## cms_provision only 
  ############################################################################
  config.vm.define "cms_provision" do |cms_provision|
    cms_provision.vm.hostname = 'cms-provision'

    cms_provision.vm.provision :shell, \
      inline: "rsync -a '/vagrant/provision' '/tmp'"

    cms_provision.vm.provision :shell, \
      inline: "id -u cms &>/dev/null || \
               adduser --disabled-password --gecos '' #{cms_user}"

    ## install basic packages and restart
    cms_provision.vm.provision :shell, path: "provision/setup/setup.sh"
    cms_provision.vm.provision :reload

    ## install user config
    cms_provision.vm.provision :shell, \
      inline: "rsync -a '/vagrant/provision' '/tmp'"
    cms_provision.vm.provision :shell,
      inline: "su -c '/tmp/provision/setup/setup_user.sh' #{cms_user}"

    ## CMS provisioning script
    cms_provision.vm.provision :shell, \
      path: "provision/setup_cms/provision_cms.sh", \
      env: { 'CMS_INSTALL_TEXLIVEFULL' => cms_install_texlivefull }
    cms_provision.vm.provision :shell, \
      path: "provision/setup_cms/provision_cmsdb.sh"

    ## add upstart script
    cms_provision.vm.provision :shell, \
      inline: "cp /tmp/provision/utils/upstart/cms.conf \
                  /etc/init/cms.conf"
    cms_provision.vm.provision :shell, \
      inline: "chown #{cms_user}:#{cms_usergroup} /etc/init/cms.conf"
    cms_provision.vm.provision :shell, \
      inline: "chmod 644 /etc/init/cms.conf"

    ## add systemd scripts
    cms_provision.vm.provision :shell, \
      path: "provision/systemd/setup_systemd.sh"

    ## provision nginx
    cms_provision.vm.provision :shell, \
      path: "provision/nginx/provision_nginx.sh"

  end

  config.vm.define "cms_ansible" do |cms_ansible|
    cms_ansible.vm.hostname = 'cms-ansible'

    cms_ansible.vm.provision :shell, \
      inline: "cat /vagrant/provision/setup/id_rsa.pub >> \
                    /root/.ssh/authorized_keys"

    cms_ansible.vm.provision :shell, \
      inline: "cp /vagrant/provision/setup/91-disable-requiretty \
                    /etc/sudoers.d/91-disable-requiretty"

  end

end
