# cpptext.sh 

run the C preprocessor (cpp) on files with hash-style comments

## Usage
```
./cpptext.sh [-f] [-C] [-v] [-h] [-t <dir>] [-D define|define=<x>] [-I includedir] cppFile [extraFiles]...
-t|--tempdir	argument is a directory for temporary files. Defaults is .cpptext
-D|--define>	add the argument as a define to pass to cpp
-I|--include	add the argument as an include file directory to pass to cpp
-o|--outfile	argument is a filename to write to.  Default is <cppFile>.cpp 
		(Use "-o -" for stdout)
-b|--blank	keep blank lines
-C|--clean	delete the directory containing temporary files
-v|--verbose	verbose mode
-h|--help	this help text

cppFile		the main file to run cpp on which optionally includes <extraFiles>.
[extraFiles]	extra files to process that are #included by <cppFile>

./cpptext.sh overwrites the file specified by -o (default is <cppFile>.cpp)
```

# dehash.sh
dehash.sh removes '#'-style comments

## Usage
```
dehash.sh [-c] [-b] [-h] filename
-c|--cpp	keep CPP directives
-b|--blank	keep blank lines
-h|--help	help
filename	file to dehash to stout or - for stdin
```

dehash was originally written to remove hash-style comments in text files
such as yaml that require the C-preprocessor for macro features. cpptext.sh
was added as a front-end for dehash.sh to do exactly that for any text files,
including yaml.

Some possible dehash command variants are:
```
 ./dehash.sh -h
 ./dehash.sh  example.txt
 ./dehash.sh -b example.txt
 ./dehash.sh -c -b example.txt
```

Note: on MacOS, you need GNU sed to run dehash.sh and cpptext.sh. To install GNU sed, please do this:
```
brew install gsed
```
and then add this line to your .bashrc:
```
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
```
and the source your .bashrc before running dehash.sh.

## makefile and Makefile

"makefile" and "Makefile" are functional makefile templates that will clone
this repo into a project.
To use them, just copy them both into a project directory that does not
already use makefiles.  If your project already does, then you likely
already know how to integrate them to your project.

There is an example in example/make that shows how to use make and cpptext
to assist with managing multiple project variants that share text files.
That example shows how to share constant #defines and configuration
#defines between text files and C / C++ files. See the files main.yaml,
config.h and pins.h in example/make for more details.

## User variables

These variables can be changed from their defaults by editting
"Makefile" or overriding them with a CLI argument to make such as
```bash
make MAIN=init.yaml
```

### OUTDIR

Where to write generated files, including the cpptext repo itself.
Unlike the other user variables, it is set in "makefile".

### MAIN

The initial/main text file that "#include"s the others. It defaults
to "main.yaml".

### SUFFIX

The suffix of source files that will be dehash-ed so that they can be
included by <MAIN>.  <MAIN> may not end up including them all however they
will be dehash-ed regardless.  See user variables DIRS and SRCS. SUFFIX
defaults to the file suffix of <MAIN>, including the '.'.

### DIRS

The directories that are searched for files ending in <SUFFIX> to dehash. 
See user variable SRCS. It defaults to ".".

### SRCS

The list of files to dehash.  It defaults *.<SUFFIX> wildcards in
the directories dpecified by DIRS

### PREFIX

Makefile.cpptext generates a single filename named <PREFIX><PROJTAG>.
PREFIX defaults to "./myProj_"

### PROJTAG

PROJTAG is used to uniquely declar the project name. It defaults to "0"
but it can be any character string of any length. To build different
project variants from the same project directory, specify a different
PROJTAG for each by overriding it on the make command line using, for
example, make PROJTAG=1.

Argument -D_PROJTAG_$(PROJTAG) is passed to the C-preprocessor so that
text sources can vary the generated file using #if directives such as:
```code
#if _PROJTAG_foo
# yaml code only for project foo goes here
#endif
Some other C preprocessor defines are passed as well.  They can be
found by reviewing the CPPDEFS definition in cpptext/Makefile.cpptext.
```

## Generated files
Makefile.cpptext generates output file <OUTDIR>/<PREFIX><PROJTAG>.<SUFFIX>
Intermediate C-preprocessed files used to generate it are stored in
directory <OUTDIR>/<PREFIX><PROJTAG>/

Both can be deleted using 'make clean'.

## Other

There are some additional comments describing cpptest features in
Makefile.

You will note that Makefile.cpptext uses dehash.sh to remove the
hash-style comments before running the files through the c-preprocessor.
It leverages a sed script to do that and sets up dehash.sh flags 
to leave the C preprocessor directives.

There are some aliases in file Bashrc also which may be helpful for
issuing esphome commands.

There is an optional Makefile.esphome that may be useful to those
using this project with esphome projects, such as the example project.
YMMV.

# Credits

Thank you to Landon Rohatensky for the exemplary esphome yaml file
https://github.com/landonr/lilygo-tdisplays3-esphome used to demonstrate
espmake configuration & build and also as used in the test subdirectory.

# Disclaimers

The author has not attempted to use cpptext with Visual Studio.

# MacOS Note

Note (repeated intentionally): on MacOS, you need GNU sed to run dehash.sh,
which dehash.sh invokes. To install GNU sed, please do this:
```
brew install gsed
```
and then add this line to your .bashrc:
```
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
```
and then 'source .bashrc' or logout and log back in.

