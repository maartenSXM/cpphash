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

## Makefile

Makefile provides a template Makefile that will clone this repo into a project.
To use it, just copy Makefile into a project directory that does not already
have a Makefile.  If your project already has a Makefile, you may be
able to clone this repo and then add the line "include cpptext/Makefile.cpptext"
into your Makefile however YMMV.

There is an example in example/make that shows how to use make and cpptext
to assist with managing multiple project variants that share text files.
Thet example shows how to sharing of constant #defines and configuration
#defines between text files and C / C++ files. See the files main.yaml,
config.h and pins.h in example/make for more details.

## Makefile User variables

These Makefile variables can be changed from their defaults by either
editting Makefile.cpptext or overriding them with a CLI argument to make such as
```bash
make MAIN=init.yaml
```

### OUTDIR

Where to write any intermediate generated files, including the
cpptext repo itself.

### MAIN

The initial/main text file that includes the others. it defaults
to "main.yaml". The suffix of the file is used as the <SUFFIX> for
teh generated file.

### PREFIX

Makefile.cpptext generates a single esphome yaml filename named $(PREFIX)$(PROJTAG).
PREFIX defaults to "./myProj_"

### PROJTAG

Makefile.cpptext a single output file named $(PREFIX)$(PROJTAG).
PROJTAG defaults to "0" but can be any character string of any length.
To build different project variants from the same project
directory, specify a different PROJTAG for each.

Argument -D_PROJTAG_$(PROJTAG) is passed to the C-preprocessor so that
text sources can vary the generated file using #if directives such as:
```code
#if _PROJTAG_foo
# yaml code only for project foo goes here
#endif
```

## Generated files
Makefile.cpptext generates output file <PREFIX><PROJTAG>.<SUFFIX>
Intermediate C-preprocessed files used to generate <PREFIX><PROJTAG>.<SUFFIX>
are stored in directory <OUTDIR>/<PREFIX><PROJTAG>/

Both can be deleted using 'make clean'.

## Other

There are some additional comments describing Makefile features in the
Makefile.

There are some aliases in file Bashrc which may be helpful for issuing
esphome commands.

Makefile.cpptext uses dehash.sh to remove the hash-style comments
before running the files through the c-preprocessor.

# Credits

Thank you to Landon Rohatensky for the exemplary esphome yaml file
https://github.com/landonr/lilygo-tdisplays3-esphome used to demonstrate
espmake configuration, build and also as used in the test subdirectory.

# Disclaimers

Tthe author has not attempted to use espmake with Visual Studio.

# MacOS Note

Note (repeated intentionally): on MacOS, you need GNU sed to run dehash.sh, which dehash.sh invokes. To install GNU sed, please do this:
```
brew install gsed
```
and then add this line to your .bashrc:
```
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
```
and then 'source .bashrc' or logout and log back in.

