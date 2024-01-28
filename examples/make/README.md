# Exemplary make project

This directory shows how to use dehash and the c-preprocessor to configure
and build any project that uses text files which has hash-style comments.

Please refer to the top-level README for details on variables that can
be set in the Makefile and/or by make-command line arguments.

To use the Makefile in this directory in your project, just copy it
into an empty directory and then type "make update" and then create
a file called main.yaml that #includes your yaml files.  If your
files are another suffix thank .yaml, you can override that with 
"make SUFFIX=.blort" or add a SUFFIX= line to Makefile

## files

The files you will find in this directory are:

### Makefile

Copied from https://github.com/maartenwrs/cpptext/blob/main/Makefile

### main.yaml
An example project's main file. If you prefer another file name, you
can set MAIN=xxx.yyy when running make

### config.h

An example of how to configure software using #define. Such a file
can be #included both by text files and by C/C++ code.

### pins.h

An example of how to configure hardware using #define. Such a file
can be #included both by text files and by C/C++ code.

### secrets.yaml
Since the example is an esphome project that used esphome's !secrets feature,
secrets.yaml is provided here but not necessary for non-esphome projects and
for projects that don't use esphome's secrets feature.

### lilygo-tdisplays3-esphome.yaml
The examplary esphome project which was modfied to show how to leverage
the C-preprocessor with text files that have hash-style comments. The original
unmodified version of this file is in the directory ../test.

