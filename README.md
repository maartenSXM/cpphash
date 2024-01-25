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

