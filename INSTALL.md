To install cpphash on Linux or Darwin, clone it from github
and then cd into cpphash and run ./install.sh

To skiphaving to confirm each step, specify the -y option.

If cpphash is only needed for text files that are not esphome
yaml, the installation of some packages that cpphash depends on
can be skipped using the -s option like this:

  ./install.sh -s

If -s is not specified install.sh also creates a virtual python
environment containing the latest esphome release and esphome dependencies. 

cpphash scipts can be run without any environment variables, once
install.sh has comleted successfullly.

To use Makefile.cpphash in a project, CH_HOME has to be set to the local
installation directory of cpphash.  That can be done by creating an
exported CH_OME environment in your shell of choice or by defining it
in the project Makefile.

To use Makefile.esphome in a project, CH_HOME is also needed. Sourcing
cpphash/Bashrc automatically sets CH_HOME and is the recommended way
to use cpphash with esphome projects.

Makefile.cpphash and Makefile.esphome use ./build as the default
build directory. That can be changed by exporting the environment
variable CH_BUILD before sourcing Bashrc.

esp_help will list the convenience aliases defined by Bashrc.

To select a specific projects, for example, do this:

  make PRJ=myfile.yaml

cpphash remembers the last project in .cpphash_prj so that you
don't have to specify a PRJ= argument to make unless you are changing
from one project to another.

ESPHOME POJECTS
---------------

For esphome projects, it is also possible to issue esphome commands
directly on the generated espmake.yaml file from the build directory.
To change to the last built project's build directory, you can use
the esp_build alias.

Then commands such as these can be issued:

  esp_build
  esphome compile espmake.yaml
  esphome upload espmake.yaml
  esphome logs espmake.yaml

See esphome -h for more details.

To burn firmware to a board, try esp_upload or esp_jtag.

To set serial port names or IP addresses used by convenience aliases,
set these environment variables.  Otherwise these defaults are
set by cpphash/Bashrc:

  _ESPMAKE_IP0=192.168.248.10
  _ESPMAKE_IP1=192.168.248.11
  _ESPMAKE_DEV0=/dev/ttyACM0
  _ESPMAKE_DEV1=/dev/ttyACM1

