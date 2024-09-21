# Exemplary make project

This directory shows how to use the c-preprocessor to configure
and build an esphome project

./makefile and ./Makefile linked directly ../..
./Makefile was editted to uncomment the line that
includes cpphash/esphome.mk.

## files

The files you will find in this directory are:

### makefile & Makefile

Copied from https://github.com/maartenSXM/cpphash

### main.yaml
An example project's main file. If you prefer another file name, you
can set MAIN=xxx.yyy either on the make command line or in ./Makefile

### config.h

An example of how to configure esphome software using #define. Such a file
can be #included both by espmake.yaml files and by C/C++ code.

### pins.h

An example of how to configure esphome hardware using #define. Such a file
can be #included both by espmake.yaml files and by C/C++ code.

### secrets.yaml
Since the example is an esphome project that used esphome's !secrets feature,
secrets.yaml is provided here but not necessary for non-esphome projects and
for projects that don't use esphome's secrets feature.

### lilygo-tdisplays3-esphome.yaml
The exemplary esphome project which was modfied to show how to leverage
the C-preprocessor with text files that have hash-style comments. The original
unmodified version of this file is in the directory ../test.

