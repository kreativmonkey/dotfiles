#!/bin/bash

install_on_debian() {
  sudo apt update 
  sudo apt install -y ansible
}

install_on_arch() {
  sudo pacman -Sy ansible
}

install_linux() {
  case $1 in
    "Arch"|"EndevourOS")
      install_on_arch
      ;;
    "Ubuntu"|"Debian"|"Linuxmint")
      install_on_debian
      ;;
  esac
}

OS="$(uname -s)"
case "${OS}" in
  Linux*)
    if [ -f /etc/os-release ]; then
      source /etc/os-release
    else
      export PRETTY_NAME="$(lsb_release -i | column --table -N Dist,ID,Name -H Dist,ID -d)"
    fi

    install_linux $PRETTY_NAME
    ;;
esac

ansible-playbook ~/.bootstrap/setup.yml --ask-become-pass
