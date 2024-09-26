This project enables the C pre-processor to be run on files containing hash-style comments. It provides shell scripts that can be used to integrate with any build system and it also provides Makefiles to enable make.  It has optional support for esphome projects, for which it was originally written.

cpphash.sh 
==========

run the C preprocessor (cpp) on files with hash-style comments

Usage
-----
```
./cpphash.sh [-f] [-C] [-v] [-h] [-t <dir>] [-D define|define=<x>] [-I includedir] cppFile [extraFiles]...
-t|--tempdir	argument is a directory for temporary files. Default is .cpphash
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

cpphash.sh processes <cppFile> and <extraFiles> using dehash.sh. The dehashed <extraFiles> are stored in <tempDir>. The dehashed <cppFile> is stored in <cppFile>.cpp. Then <cppFile> is run through the C pre-processor with -I <tempDir> as the first include directory path.

Note: ./cpphash.sh overwrites the file specified by -o (default is <cppFile>.cpp)
```

dehash.sh
=========
dehash.sh removes '#'-style comments 

Usage
-----
```
dehash.sh [-c] [-b] [-h] filename
-c|--cpp	keep CPP directives
-b|--blank	keep blank lines
-h|--help	help
-o|--out <file>	file to write output to, else stdout
filename	file to dehash to stout or - for stdin
```

dehash.sh was removes hash style comments from one file.  Use cpphash.sh
to run dehash.sh on multiple files and to run teh C-preprocessor on one of
them that includes one or more of the others.

Some possible dehash command variants are:
```
 ./dehash.sh -h
 ./dehash.sh  example.txt
 ./dehash.sh -b example.txt
 ./dehash.sh -c -b example.txt
```

espmerge.sh
===========
espmerge.sh: reads esphome yaml and outputs merged esphome yaml.

Usage
-----
```
espmerge.sh <input.yaml >output.yaml
```

espmerge.sh parses yaml into common blocks and merges sections that
are repeated *and* named.

Common blocks are merged backwards in the output by referencing tags
specified in "id: <tag>" yaml lines. The first common block to
specify a unique <tag> is the destination for subsequent references.
lines in subsequent blocks are merged at the end of the block
that declared "id: <tag>" first. Array elements are each treated
as common blocks so it is possible to merge into an array element
as long as it declares itself using "id: <tag>".

After running espmerge.sh, it is advised to merge remaining repeated
sections that are not named with "id: <tag>" by piping the espmerge.sh
output through this pipe which sets up each section as a separate yaml
document and then removes yaml comments;
```
awk '/^[[:alnum:]_]/{print "---"} | yq '... comments=""' esphome.yaml
```
and then piping its out into yq to merge the multiple documents using:

```
  yq eval-all '. as $item ireduce ({}; . *+ $item)'
```
For an example of how this is done, refer to the yamlmerge.sh implementation.

yamlmerge.sh
============
yamlmerge.sh: merge duplicate map keys in non-compliant yaml

Usage
-----
yamlmerge.sh: [-okseEqh] [-o outfile] <file.yaml>\n
  -o|--outfile	File to write to, else stdout.
  -k|--keep	Keep yaml comments.
  -s|--sort	Sort the map keys.
  -e|--esphoist	Hoist the esphome: and esp32: map keys to output first.
  -E|--espmerge	Enable esphome item merging using \"id\": references.
  -q|--quiet	Do not output the number of merged components.
  -h|--help	Output this help.

<file.yaml>	The yaml file to merge, else stdin.

yamlmerge.sh processes a single yaml files using these steps:
```
  First, yaml comments are optionally removed using yq.
  Then espmerge.sh is run if requested.
  Then map keys are each put in their own yaml document, using awk.
  Then map keys are merged using yq.
  Then map keys are optionally sorted using yq.
  Then esphome map keys are optionally hoisted using yq.
```

Installation
============

Please refer to INSTALL.md for information relating to cpphash installation.

How to use this repo
====================

Use the cpphash.sh, dehash.sh, espmerge.sh or yamlmerge.sh scripts
individually or optionally use the Makefile.cpphash or Makefile.esphome
makefiles.

Makefile.cpphash implements a cpphash project build mechanism using make.
See examples/stackoverflow for an example of how to use it,.
Makefile.cpphash implements a cpphash project build mechanism using make
specifically for esphome yaml files. See examples/esphome for an example
of how to use it.

To use either Makefile.cpphash or Makefile.esphome, copy one of them into
a project directory that does not already use make. If your project already
does, then you likely already know how to integrate them into your project.

For an example of a larger project that uses cpphash and has customized
Makefile.esphome, see github.com/maartenSXM/GrowOS

# Credits

Thank you to Landon Rohatensky for the exemplary esphome yaml file
https://github.com/landonr/lilygo-tdisplays3-esphome used to demonstrate
configuration & build and also as used in the test subdirectory.

