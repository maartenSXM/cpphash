#!/usr/bin/env bash

# This script can be re-run as it will only install things if needed.

set -o nounset

export _DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" \
                                                &> /dev/null && pwd )
declare -i verbose=0
declare -i skip_esphome=0
declare -i autoconfirm=0
declare VENV="$_DIR/venv"

declare usage="${0##*/}: install cpphash on Linux or MacOS

Usage: ${0##*/}: [-V] [-s] [-y] [-v <venv>]\n
  -V|--verbose\t\tenable verbose output.
  -s|--skip_esphome\tskip installation of esphome components.
  -y|--yes\t\tpre-confirm all steps.
  -h|--help\t\toutput usage.
  -v|--venv\t\tspecify virtual env direct. <venv> defaults to:
\t\t\t$_DIR/venv

This script is from git repo github.com/maartenSXM/cpphash.
Note: This script does not vet arguments securely. Do not setuid or host it.
"

while [[ $# > 0 ]]; do
  case $1 in
    -V|--verbose) verbose=1; shift 1;;
    -s|--skip_esphome) skip_esphome=1; shift 1;;
    -y|--yes)	autoconfirm=1; shift 1;;
    -h|--help)	printf "$usage"; exit 0;;
    -v|--venv)	VENV=$2; shift 2;;
    *) echo "$0: bad argument $1"; exit 1;;
  esac
done

if [[ "$(uname)" != "Linux" && "$(uname)" != "Darwin" ]]; then
  echo "$0: only supports Linux and Mac for now, sorry"
  exit 1
fi

confirm() {
  if ((verbose)); then
   echo "About to $1"
  else
    echo "About to $1 using this command:"
    echo "$2"
  fi

  if ((autoconfirm==0)); then
    while :; do
      read -p "Are you sure? [YyNnQq] " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Qq]$ ]]; then
	exit 1
      fi
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1
      fi
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        break
      fi
    done
  fi

  eval "$2"

  if (($? != 0)); then
    echo "$0: $1 failed. Installation aborted."
    exit 1
  fi
}

if [[ "$(uname)" == "Darwin" ]]; then
  if [[ "$(command -v brew)" == "" ]]; then
    confirm "Install brew package" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  fi
  if [[ "$(command -v brew)" == "" ]]; then
    echo "$0: brew is required to continue. Installation aborted."
    exit 1
  fi
  if [ -z "${BASH_VERSINFO:-}" ]; then
    confirm "Install brew bash package"	      "brew install bash"
  else
    if (($BASH_VERSINFO < 4)); then
      confirm "Install brew bash package"     "brew install bash"
    fi
  fi
  if [[ "$(command -v yq)" == "" ]]; then
    confirm "Install brew yq package"	      "brew install yq"
  fi
  if [[ "$(command -v gsed)" == "" ]]; then
    confirm "Install brew gnu sed package"    "brew install gnu-sed"
  fi
  if [[ "$(command -v md5sum)" == "" ]]; then
    confirm "Install brew md5sha1sum package" "brew install md5sha1sum"
  fi
  brew list gcc &>/dev/null
  if [ $? -ne 0 ]; then
    confirm "Install gcc" "brew install gcc"
  fi
fi

# If esphome is being installed this message is output at the end so
# that it is more easily noticeable. Else, output it now and exit.

if ((skip_esphome==1)); then
  if [[ "$(uname)" == "Linux" && "$(command -v yq)" == "" ]]; then
    printf "\nPlease install the yq package manually using:"
    printf "   sudo apt install yq || sudo snap install yq\n\n"
  fi
  exit 0
fi

# If we get here, esphome is also being installed.

if [ ! -d "$VENV" ]; then
  confirm "create a python virtual environment in $VENV" "python3 -m venv $VENV"
fi

if [ ! -d "$VENV" ]; then
  echo "$0: A virtual environment is required to continue. Installation aborted."
  exit 1
fi

source $VENV/bin/activate

if [[ "$(uname)" == "Darwin" ]]; then
  pip3 -q show wheel 2>/dev/null
  if [ $? -ne 0 ]; then
    confirm "install python wheel package"    "pip3 install wheel"
  fi
fi

pip3 show pillow 2>/dev/null | grep -q "10.2.0"
if [ $? -ne 0 ]; then
  confirm "Install python pillow package"    'pip3 install "pillow==10.2.0"'
fi

pip3 -q show setuptools 2>/dev/null
if [ $? -ne 0 ]; then
  confirm "Install python setuptools package" "pip3 install setuptools"
fi

pip3 -q show esphome 2>/dev/null
if [ $? -ne 0 ]; then
confirm "Install python esphome package"    "pip3 install esphome"
fi

if [[ "$(uname)" == "Linux" && "$(command -v yq)" == "" ]]; then
  printf "\nPlease install the yq package manually using:"
  printf "   sudo apt install yq || sudo snap install yq\n\n"
fi

