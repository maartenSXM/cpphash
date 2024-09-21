#!/usr/bin/env bash

if [[ "$(sed --version 2>/dev/null)" =~ "GNU" ]]; then
  SED=sed
else
  if [[ "$(which gsed)" =~ "gsed" ]]; then
    SED=gsed
  else
    echo "$(basename $0): GNU sed not found. Please install it"
    exit -1
  fi
fi

name=`basename $0`
scriptpath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
dehash="$scriptpath/dehash.sh -c"
postcpp=cat
yamlmerge="$scriptpath/yamlmerge.sh"

help="$name: run the Gnu C preprocessor (cpp) on files with hash-style
      comments by de-hashing them first.

Usage: $name [-f] [-w] [-W] [-v] [-n] [-h] [-t <dir>]
       [-D <define>|<define>=<x>]... [-I <includeDir>]...
       cppFile <extraFiles>...

 -D		 Set defines for cpp. Argument required.
 -I		 Set include file directories for cpp. Argument required.
 -t|--tempdir    Set the temporary file directory. Defaults to \".cpphash/\".
 -o|--outfile    Set the output file name. Default is <cppFile>.cpp.
                 (Use \"-o -\" for stdout).
 -y|--yaml-merge after cpp-ing, merge duplicate yaml map keys in <cppFile>.
 -f|--force      allow $name to overwrite an existing $outfile.
 -b|--blank      Keep blank lines.
 -w|--wipe       Delete the temporary file directory contents and continue.
 -W|--wipe-only  Delete the temporary file directory and exit.
 -v|--verbose    Verbose mode.
 -n|--no-exec    Don\'t execute anything. Enables -v.
 -h|--help       Print out this help text.

<cppFile> is run through the C preprcoessor. It is a mandatory argument.
The optional [extraFiles]... are de-hashed for #include-ing by <cppFile>.

Please note that $name overwrites the output file which defaults to
<cppFile>.cpp>. Also, please note that the mandatory arguments to -D
and -I are positional and so there must be a space between -D and -I
and their arguments.

This script is from git repo github.com/maartenSXM/cpphash.
Note: this script does not vet arguments securely. Do not setuid or host it.
"

doit=1
wipe=0
wipeonly=0
verbose=0
force=0
tempdir=.cpphash

gcc="gcc -x c -C -undef -nostdinc -E -P -Wno-endif-labels -Wundef -Werror"

while [[ $# > 0 ]]
do
  case $1 in
    -D|--define)     cppdefs="$cppdefs -D $2"; shift 2;;
    -I|--include)    cppincs="$cppincs -I $2"; shift 2;;
    -t|--tempdir)    tempdir="$2"; shift 2;; 
    -o|--outfile)    outfile="$2"; shift 2;; 
    -y|--yaml-merge) postcpp=$yamlmerge; shift;; 
    -b|--blank)      dehash="$dehash -b"; gcc="$gcc -traditional-cpp"; shift;; 
    -f|--force)      force=1; shift;; 
    -c|--wipe)       wipe=1; shift;; 
    -C|--wipe-only)  wipe=1; wipeonly=1; shift;; 
    -v|--verbose)    verbose=1; shift;; 
    -n|--no-exec)    doit=0; verbose=1; shift;; 
    -h|--help)       echo -e "$help"; exit 0;; 
    *) break
  esac
done

if ((wipe)); then
   ((verbose))   && echo rm -rf $tempdir
   ((doit))      && rm -rf "$tempdir"
   ((wipeonly))  && exit
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

  # check that the caller specified a text file 
  if file "$fullname" | grep -qv 'ASCII\|UTF-8'; then
    echo "$0: $fullname is not an ASCII or UTF-8 text file"
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
   ((verbose)) && echo "mkdir -p $dehashoutdir"
   if ((doit)); then mkdir -p "$dehashoutdir" || exit; fi
  fi

  filedir="`dirname $fullname`"
  if [ $filedir != "." ]; then
    dehashout="$tempdir/$filedir/$filename"
  else
    dehashout="$tempdir/$filename"
  fi
  
  ((verbose)) && echo "$0: $dehash $fullname >$dehashout"
  if ((doit)); then $dehash "$fullname" >"$dehashout" || exit; fi
}

# grok the main filename and setup to cpp it from $tempdir
mainfile="$1"
filename=$(basename -- "$mainfile")
filecppdir=$(dirname "$mainfile")
if [ "$filecppdir" != "." ]; then
  cppfile="$tempdir/$filecppdir/$filename"
else
  cppfile="$tempdir/$filename"
fi

if [ "$outfile" == "" ]; then
  outfile="${filename}.cpt"
else
  if [ "$outfile" == "-" ]; then
    outfile=/dev/stdout
  fi
fi

if [ "$outfile" == "$cppfile" ]; then
    echo "$0: the input file and output file names must be different"
fi

if ((!force)) && [ "$outfile" != "/dev/stdout" ] && [ -f "$outfile" ]; then
    echo "$0: will not overwrite $outfile unless the -f option is specified."
fi

# dehash all specified files, including the main file
for file in "$@"; do
    run_dehash "$file"
done

# after cpp, the sed restores the shebang that dehash.sh may have found

((verbose)) && echo "$0: $gcc -I \"$tempdir\" -I . $cppincs $cppdefs \"$cppfile\" | $SED '1 {s,^__SHEBANG__,#"'!'",}' | $postcpp > \"$outfile\""

((doit)) && $gcc -I "$tempdir" -I . $cppincs $cppdefs "$cppfile" | $SED '1 {s,^__SHEBANG__,#!,}' | $postcpp > "$outfile"

exit
