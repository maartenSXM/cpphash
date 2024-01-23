#!/bin/bash
scriptpath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
dehash="$scriptpath/dehash.sh"

verbose=0
clean=0
tempdir=.cpptext
gcc="gcc -x c -C -undef -nostdinc -E -P -Wno-endif-labels"
help="$0: run the C preprocessor (cpp) on files with hash-style comments
Usage: $0 [-f] [-C] [-v] [-h] [-t <dir>] [-D define|define=<x>] [-I includedir] cppFile [extraFiles]...
-t|--tempdir\targument is a directory for temporary files. Defaults is .cpptext
-D|--define>\tadd the argument as a define to pass to cpp
-I|--include\tadd the argument as an include file directory to pass to cpp
-o|--outfile\targument is a filename to write to.  Default is <cppFile>.cpp 
\t\t(Use \"-o -\" for stdout)
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
    -D|--define) cppdefs="$cppdefs -D $2"; shift 2;;
    -I|--include) cppincs="$cppincs -I $2"; shift 2;;
    -t|--tempdir) tempdir="$2"; shift 2;; 
    -o|--outfile) outfile="$2"; shift 2;; 
    -C|--clean) clean=1; shift;; 
    -v|--verbose) verbose=1; shift;; 
    -h|--help) echo -e "$help"; exit 0;; 
    *) break
  esac
done

if [ $clean == 1 ]; then
  if [ $verbose == 1 ]; then
    echo rm -rf $tempdir
  fi
  rm -rf $tempdir
  exit $?
fi

run_dehash() {
  fullname="$1"
  filename=$(basename -- "$fullname")

  if [ ! -e $fullname ]; then
    echo "$0: $fullname not found"
    exit -1
  fi
  if [ ! -f $fullname ]; then
    echo "$0: $fullname is not a regular file"
    exit -1
  fi
  if LC_ALL=C grep -q '[^[:cntrl:][:print:]]' $fullname; then
    echo "$0: $fullname is not an ASCII text file"
    exit -1
  fi

  if [ $tempdir != "-" ]; then
    dehashout=$tempdir/$fullname
    fullnamedir="`dirname $fullname`"
    if [ $fullnamedir == "." ]; then
      dehashoutdir="$tempdir"
    else
      dehashoutdir="$tempdir/$fullnamedir"
    fi
    if [ ! -d $dehashoutdir ]; then
      # create any $tempdir path including $file subdirectories
      if [ $verbose == 1 ]; then
        echo "mkdir -p $dehashoutdir"
      fi
      mkdir -p "$dehashoutdir"
    fi
  else
    dehashout=/dev/stdout
  fi
  filedir=`dirname $fullname`
  if [ $filedir != "." ]; then
    dehashout=$tempdir/$filedir/$filename"
  else
    dehashout=$tempdir/$filename"
  fi
  if [ $verbose == 1 ]; then
    echo "$0: ./dehash.sh -c $fullname >$dehashout"
  fi
  $dehash -c "$fullname" >"$dehashout"
}

mainfile=$1
# dehash all specified files including the main file
for file in "$@"; do
    run_dehash $file
done

# grok the main filename and setup to cpp it from $tempdir
filename=$(basename -- "$mainfile")
filecppdir=`dirname $mainfile`
if [ $filecppdir != "." ]; then
  cppfile="$tempdir/$filecppdir/$filename"
else
  cppfile="$tempdir/$filename"
fi

if [ "$outfile" == "" ]; then
  outfile="${filename}.cpp"
fi

# check if mainfile has a shebang and put it back if it does. Else, don't
# use -traditional-cpp since it doesnt process indented directives correctly.

firstline=$(head -n 1 "$mainfile")
if [ ${firstline:0:2} == "#!" ]; then
  if [ $verbose == 1 ]; then
      echo "$0: $gcc -traditional-cpp -I $tempdir -I . $cppincs $cppdefs $cppfile | sed '1 {s,^#!(.*)$,__SHEBANG_,#"'!'",}' > $outfile"
  fi
  $gcc -traditional-cpp -I $tempdir -I . $cppincs $cppdefs $cppfile | sed '1 {s,^__SHEBANG_,#!,}' > "$outfile"
  exit $?
else
  if [ $verbose == 1 ]; then
      echo "$0: $gcc -I $tempdir -I . $cppincs $cppdefs $cppfile > $outfile"
  fi
  $gcc -I $tempdir -I . $cppincs $cppdefs $cppfile > "$outfile"
  exit $?
fi

# no fall through ...
