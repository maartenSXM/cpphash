To install cpphash on Linux or Darwin, clone it from github
and then cd into cpphash and run ./install.sh -y

To confirm each step, do not specify the -y option.

If cpphash is only needed for text files that are not esphome
yaml, teh installation of esphome depencies can be skipped using
the -s option like this:

  ./install.sh -s -y

cpphash/install.sh will install its dependencies.  If -s is not
specified t also creates a virtual python environment containing
the latest esphome release and esphome dependencies. 

Once installed, cpphash can be activated using 'source Bashrc' for
those using it with esphome. If cpphash is being used without
esphome, do noyt source the Bashrc and instead set environment
variable CH_HOME to the cpphash install directory using, for example:

  export CH_HOME=~/git/cpphash

Alternatively, it can be set in Makefile.cpphash.

Makefile.cpphash and Makefile.espmake use ./build as the build directory.
That can be changed by editting the Makefile.cpphash or (Makefile.espmake
and Bashrc).

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
  _ESPMAKE_DEV0=/dev/ttyACM1

