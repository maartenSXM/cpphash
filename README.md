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
dehash.sh [-c] [-b] [-h] [-o file] filename
-c|--cpp	keep CPP directives
-b|--blank	keep blank lines
-h|--help	help
-o|--out <file>	file to write output else stdout
filename	file to dehash or - for stdin.
```

dehash.sh was removes hash style comments from one file.  Use cpphash.sh
to run dehash.sh on multiple files and to run the C-preprocessor on one of
them that includes one or more of the others.

Some possible dehash command variants are:
```
 ./dehash.sh -h
 ./dehash.sh  example.txt
 ./dehash.sh -b example.txt
 ./dehash.sh -c -b example.txt
```

idmerge.sh
===========
idmerge.sh: merge yaml common blocks with an id: tag

Usage
-----
```
Usage: idmerge.sh: [-q] [-p] [-m] [-h] [-t tag] [-o outfile] <file.yaml>
  -t|--tag	 Item tag that uniquely names what to merge. Defaults to "id".
  -o|--outfile	 File to write to, else stdout.
  -q|--quiet	 Do not output operational feedback to stdout.
  -p|--parseinfo Output input parser debug info to stderr
  -m|--mergeinfo Output merge debug info to stderr
  -h|--help	 Output this help.

<file.yaml>\tThe yaml file to merge, else stdin.
```

idmerge.sh parses yaml into common blocks and merges sections that
are repeated *and* named.

Common blocks are merged backwards in the output by referencing tags
specified in "id: <tag>" yaml lines. The first common block to
specify a unique <tag> is the destination for subsequent references.
lines in subsequent blocks are merged at the end of the block
that declared "id: <tag>" first. Array elements are each treated
as common blocks so it is possible to merge into an array element
as long as it declares itself using "id: <tag>".

After running idmerge.sh, it is advised to merge remaining repeated
sections that are not named with "id: <tag>" by piping the idmerge.sh
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
```
yamlmerge.sh: [-o] [-k] [-s] [-e] [-E] [-q] [-h] [-o outfile] <file.yaml>\n
  -o|--outfile	File to write to, else stdout.
  -k|--keep	Keep yaml comments.
  -s|--sort	Sort the map keys.
  -e|--esphoist	Hoist the esphome: and esp32: map keys to output first.
  -i|--idmerge	Enable item merging using \"id\": tag references.
  -t|--tag	Item tag that uniquely names what to merge. Defaults to "id".
  -q|--quiet	Do not output the number of merged components.
  -h|--help	Output this help.

<file.yaml>	The yaml file to merge, else stdin.
```

yamlmerge.sh processes a single yaml files using these steps:
```
  First, yaml comments are optionally removed using yq.
  Then idmerge.sh is run if requested.
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

Use the cpphash.sh, dehash.sh, idmerge.sh or yamlmerge.sh scripts
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

