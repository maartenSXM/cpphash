#!/bin/bash

HELP="`basename $0` merges offending duplicate map keys in non-compliant yaml

Usage: `basename $0` [-o outfile] <yamlfile>
  -o|--outfile\tfile to write to, else stdout
  -q|--quiet\tdo not output the number of merged components
<yamlfile>\tyaml file to operate, else stdin

This script is from git repo github.com/maartenSXM/cpptext.
Note: This script does not vet arguments securely. Do not setuid or host it.
"

quiet=0
outfile=/dev/stdout
removecomments=(yq '... comments=\"\"')

while [[ $# > 0 ]]
do
  case $1 in
    -o|--out)	    outfile="$2"; shift 2;;
    -c|--comments)  removecomments=cat; shift 1;;
    -q|--quiet)	    quiet=1; shift;;
    *) break
  esac
done

yaml="$1"
if [ "$yaml" == "" ]; then
  yaml=/dev/stdin
fi

# yq's merge feature merges across multiple documents in one or multiple
# files but not within a single yaml document in a single file. Thus,
# awk is needed to split each map key into a separate yaml document
# within a single file. Map keys are delimited in yaml by '---'.

# The awk script detects map keys by checking for alphanumeric
# characters or an underscore in column 1 and separates them into
# distinct yaml documents by outputting '---'.

# yaml comments are first removed. To keep them, use the -c option

eval $removecomments "$yaml" |				    \
    awk '/^[[:alnum:]_]/{print "---"}; {print $0}' |	    \
    yq eval-all '. as $item ireduce ({}; . *+ $item)' > "$outfile"
status=$?

((quiet)) && exit $status

if [ "$yaml" != "/dev/stdin" ]; then
  if [ "$outfile" != "/dev/stdout" ]; then
    ncomps=`grep '^\S' $yaml | wc -l`
    printf '%b' "$0: \033[1mMerged $ncomps"	1>&2
    printf '%b\n' " components.\033[0m"		1>&2
  fi
fi

exit $status
