#!/usr/bin/env bash

quiet_dpkg='-o=Dpkg::Use-Pty=0'

function quiet_update {
    apt-get -qq -y update
}

function quiet_upgrade {
    apt-get -qq -y "$quiet_dpkg" upgrade &>/dev/null
}

function quiet_install {
    apt-get -qq -y "$quiet_dpkg" install "$@" &>/dev/null
}
