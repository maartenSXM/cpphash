#!/usr/bin/env bash

set -o nounset		# require variables to be set before referenced

if ! [ -x "$(command -v yq)" ]; then
  echo '$0: yq is not installed. Install it' >&2
fi

declare -i status
declare -r me=${0##*/}  # basename of this script
declare -r cpphashDir=$(dirname "$0")

declare -r usage="$me: merges duplicate map keys in non-compliant yaml

Usage: $me: [-okseEqh] [-o outfile] <file.yaml>\n
  -o|--outfile\tFile to write to, else stdout.
  -k|--keep\tKeep yaml comments.
  -s|--sort\tSort the map keys.
  -e|--esphoist\tHoist the esphome: and esp32: map keys to output first.
  -E|--espmerge\tEnable esphome item merging using \"id\": references.
  -q|--quiet\tdo not output the number of merged components.
  -h|--help\toutput this help.
<file.yaml>\tyaml file to operate, else stdin.

This script is from git repo github.com/maartenSXM/cpphash.
Note: This script does not vet arguments securely. Do not setuid or host it.
"

quiet=0
outfile=/dev/stdout

DECOMMENT() { yq '... comments=""'; }
ESPMERGE()  { "$cpphashDir/espmerge.sh"; }
MAP2DOC()   { awk '/^[[:alnum:]_]/{print "---"}; {print $0}'; }
YQMERGE()   { yq eval-all '. as $item ireduce ({}; . *+ $item)'; }
YQSORT()    { yq -P 'sort_keys(.)'; }
ESPHOIST()  { yq 'pick((["esphome", "esp32"] + keys) | unique)'; }

decomment=DECOMMENT
espmerge=cat
map2doc=MAP2DOC
yqmerge=YQMERGE
yqsort=cat
esphoist=cat

while [[ $# > 0 ]]
do
  case $1 in
    -o|--out)	outfile="$2"; shift 2;;
    -h|--help)	printf "$usage"; exit 0;;
    -k|--keep)  decomment=cat; shift 1;;
    -s|--sort)  yqsort=YQSORT; shift 1;;
    -e|--esphoist) esphoist=ESPHOIST; shift 1;;
    -E|--espmerge) espmerge=ESPMERGE; shift 1;;
    -q|--quiet)	quiet=1; shift;;
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

# yamlmerge.sh processes a single yaml files using these steps:
#   First, yaml comments are optionally removed using yq.
#   Then espmerge.sh is run if requested.
#   Then map keys are each put in their own yaml document, using awk.
#   Then map keys are merged using yq.
#   Then map keys are optionally sorted using yq.
#   Then esphome map keys are optionally hoisted using yq.

$decomment < "$yaml" | $espmerge | $map2doc | \
    $yqmerge | $yqsort | $esphoist > "$outfile"

status=$?

((status != 0)) && exit $status
((quiet)) && exit 0

# Optionally output how many yaml map keys were processed.

if [ "$yaml" != "/dev/stdin" ]; then
  if [ "$outfile" != "/dev/stdout" ]; then
    ncompsin=$(grep -E '^[[:alnum:]_]+:$' $yaml | wc -l)
    ncompsout=$(grep -E '^[[:alnum:]_]+:$' $outfile | wc -l)
    shopt -s extglob
    ncompsin="${ncompsin##*( )}"	# trim leading whitespace
    ncompsout="${ncompsout##*( )}"	# trim leading whitespace
    shopt -u extglob
    printf '%b' "$0: \033[1mMerged $ncompsin" 1>&2
    printf '%b\n' " components into $ncompsout.\033[0m"	1>&2
  fi
fi

exit $status
