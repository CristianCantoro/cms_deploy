# cms deploy

This repo is a collection of scripts (and an ansible playbook) to deploy an installation of [CMS (Contest Management System)](https://github.com/cms-dev/cms).

You can use [vagrant](https://www.vagrantup.com/) to have a local deployment - on a virtual machine - of CMS `v1.2.0` (release in Febraury 2015). Work is in progress to also support the latest release of CMS `v1.3.rc0`.

## Installation instructions

The easiest way to have a local instance of CMS up-and-running is using [VirtualBox](https://www.virtualbox.org/) and [vagrant](https://www.vagrantup.com/).


To launch a local install of CMS do the following:
```bash
user@host:~$ git clone git@github.com:CristianCantoro/cms_deploy.git
user@host:~$ cd cms_deploy
user@host:~/cms_deploy$ vagrant up cms_provision
```
This will take several minutes.

### Options

These are the options you have issuing the command above:

```bash
[CMS_INSTALL_TEXLIVEFULL=true] vagrant up [(cms_provision|cms_ansible)]
```

If you specify the environment variable `CMS_INSTALL_TEXLIVEFULL`, during the installation the additional package `texlive-full` will be installed. This package alone requires dowloading ~3GB and will probably take several minutes. 

## Running CMS in your local virtual machine

You can login to the virtual machine using `vagrant ssh cms_provision`, you will be logged in as the user `vagrant` which has `sudo` privileges with no password.
```bash
vagrant@cms-provision:~$
```

CMS is run as the user `cms`, you can change to that user with:
```bash
vagrant@cms-provision:~$ sudo su cms
╭─cms@cms-provision /home/vagrant
╰─$
```
(you will notice the change of the shell and prompt)

After [creating a contest](https://cms.readthedocs.io/en/v1.3/Creating%20a%20contest.html), you can start CMS - as user `vagrant` with:
```bash
vagrant@cms-provision:~$ sudo service cms start
cms start/running, process 14849
```

You can check a control panel for CMS with the following commands:
```bash
vagrant@cms-provision:~$ sudo su cms
╭─cms@cms-provision /home/vagrant
╰─$ cd
╭─cms@cms-provision ~
╰─$ tmux attach -t cms
```

A [tmux](https://github.com/tmux/tmux/wiki) session will open. Press `Ctrl+A D` to detach.


## Using your local CMS instance

To use your local CMS instance, first get the IP address of the VirtualBox local [private network](https://www.virtualbox.org/manual/ch06.html).

You can find the IP address of the host machine on the private network by looking at the `vboxnet0` interface with the `ifconfig` command on the host:
```bash
user@host:~$ ip -4 addr show dev vboxnet0
    ...
    inet 172.28.128.1/24 brd 172.28.128.255 scope global vboxnet0
```

and on the virtual machine:
```bash
vagrant@cms-provision:~$ ip -4 addr show eth1
    ...
    inet 172.28.128.15/24 brd 172.28.128.255 scope global eth1
```

The local CMS instance is thus available at: `http://172.28.128.15/`.
