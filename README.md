cms deploy
----------

This repo is a collection of scripts (and an ansible playbook) to deploy an installation of [CMS (Contest Management System)](https://github.com/cms-dev/cms).

You can use [vagrant](https://www.vagrantup.com/) to have a local deployment - on a virtual machine - of CMS `v1.2.0` (release in Febraury 2015). Work is in progress to also support the latest release of CMS `v1.3.rc0`.

## Installation instructions

The easiest way to have a local instance of CMS up-and-running is using [VirtualBox](https://www.virtualbox.org/) and [vagrant](https://www.vagrantup.com/).

To launch a local install of CMS do the following:
```
git clone git@github.com:CristianCantoro/cms_deploy.git
cd cms_deploy
vagrant up cms_provision
```
