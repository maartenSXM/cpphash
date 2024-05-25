#!/bin/bash
scriptpath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
dehash="$scriptpath/dehash.sh -c"

verbose=0
clean=0
tempdir=.cpptext
gcc="gcc -x c -C -undef -nostdinc -E -P -Wno-endif-labels -Wunder -Werror"
help="$0: run the C preprocessor (cpp) on files with hash-style comments
Usage: $0 [-f] [-C] [-v] [-h] [-t <dir>] [-D define|define=<x>] [-I includedir] cppFile [extraFiles]...
-t|--tempdir\targument is a directory for temporary files. Defaults is .cpptext
-D|--define>\tadd the argument as a define to pass to cpp
-I|--include\tadd the argument as an include file directory to pass to cpp
-o|--outfile\targument is a filename to write to.  Default is <cppFile>.cpp 
\t\t(Use \"-o -\" for stdout)
-b|--blank\tkeep blank lines
-C|--clean\tdelete the directory containing temporary files
-v|--verbose\tverbose mode
-h|--help\tthis help text

cppFile\t\tthe main file to run cpp on which optionally includes <extraFiles>.
[extraFiles]\textra files to process that are #included by <cppFile>

$0 overwrites the file specified by -o (default is <cppFile>.cpp)
"

while [[ $# > 0 ]]
do
  case $1 in
    -D|--define)  cppdefs="$cppdefs -D $2"; shift 2;;
    -I|--include) cppincs="$cppincs -I $2"; shift 2;;
    -t|--tempdir) tempdir="$2"; shift 2;; 
    -o|--outfile) outfile="$2"; shift 2;; 
    -b|--blank)   dehash="$dehash -b"; gcc="$gcc -traditional-cpp"; shift;; 
    -C|--clean)   clean=1; shift;; 
    -v|--verbose) verbose=1; shift;; 
    -h|--help)    echo -e "$help"; exit 0;; 
    *) break
  esac
done

if [ $clean == 1 ]; then
  if [ $verbose == 1 ]; then
    echo rm -rf $tempdir
  fi
  rm -rf "$tempdir"
  exit $?
fi

run_dehash() {
  fullname=$1
  filename=$(basename -- "$fullname")

  if [ ! -e "$fullname" ]; then
    echo "$0: $fullname not found"
    exit -1
  fi
  if [ ! -f "$fullname" ]; then
    echo "$0: $fullname is not a regular file"
    exit -1
  fi
  if LC_ALL=C grep -q '[^[:cntrl:][:print:]]' "$fullname"; then
    echo "$0: $fullname is not an ASCII text file"
    exit -1
  fi

  dehashout="$tempdir/$fullname"
  fullnamedir="`dirname $fullname`"
  if [ "$fullnamedir" == "." ]; then
    dehashoutdir="$tempdir"
  else
    dehashoutdir="$tempdir/$fullnamedir"
  fi

  # create the $tempdir path including subdirectories, if needed
  if [ ! -d "$dehashoutdir" ]; then
    if [ $verbose == 1 ]; then
      echo "mkdir -p $dehashoutdir"
    fi
    mkdir -p "$dehashoutdir"
  fi

  filedir=`dirname $fullname`
  if [ $filedir != "." ]; then
    dehashout="$tempdir/$filedir/$filename"
  else
    dehashout="$tempdir/$filename"
  fi
  
  if [ $verbose == 1 ]; then
    echo "$0: $dehash $fullname >$dehashout"
  fi
  $dehash "$fullname" >"$dehashout"
}

mainfile=$1
# dehash all specified files, including the main file
for file in "$@"; do
    run_dehash "$file"
done

# grok the main filename and setup to cpp it from $tempdir
filename=$(basename -- "$mainfile")
filecppdir="`dirname $mainfile`"
if [ $filecppdir != "." ]; then
  cppfile="$tempdir/$filecppdir/$filename"
else
  cppfile="$tempdir/$filename"
fi

if [ "$outfile" == "" ]; then
  outfile="${filename}.cpp"
else
  if [ "$outfile" == "-" ]; then
    outfile=/dev/stdout
  fi
fi

# the sed restores the shebang that dehash.sh may have found

if [ $verbose == 1 ]; then
  echo "$0: $gcc -I \"$tempdir\" -I . $cppincs $cppdefs \"$cppfile\" | sed '1 {s,^__SHEBANG__,#"'!'",}' > \"$outfile\""
fi

$gcc -I "$tempdir" -I . $cppincs $cppdefs "$cppfile" | sed '1 {s,^__SHEBANG__,#!,}' > "$outfile"

exit $?
