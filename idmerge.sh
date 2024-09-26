#!/usr/bin/env bash

# espmerge.sh: read esphome yaml and output merged esphome yaml.

# Common blocks are merged backwards in the output by referencing tags
# specified in "id: <tag>" yaml lines. The first common block to
# specify a unique <tag> is the destination for subsequent references.
# lines in subsequent blocks are merged at the end of the block 
# that declared "id: <tag>" first. Array elements are each treated
# as common blocks so it is possible to merge  into an array element
# as long as it declares itself using "id: <tag>"

# Usage: espmerge.sh <input.yaml >output.yaml

# After running espmerge.sh, it is advised to postprocess the yaml with
# awk '/^[[:alnum:]_]/{print "---"} | yq '... comments=""' esphome.yaml
# before piping it into yq to merge sections using:

#   yq eval-all '. as $item ireduce ({}; . *+ $item)'

# Maarten's Law: "Everything is more complicated than it should be."
# For proof of Maarten's Law, uncomment the next line and run this script.

#   more espmerge.sh; exit

# Require all variables to be declared - to catch variable typos early.

set -e
set -o nounset
set -o pipefail

if (($BASH_VERSINFO < 4)); then
  echo "$0 *** bash must be at version 4 or greater. Install it. ***" >&2
  exit -1
fi

declare -i chatty=1	    # some operational feedback to stdout
declare -i dbgParse=0	    # input parser debug output to stderr
declare -i dbgMerge=0	    # merge engine debug output to stderr

# Tips for debugging:

# 1. This program outputs lines numbers starting at 1.
#    To dump line numbers of a test yaml file, use nl. Eg: nl test1.yaml

# 2. For large yaml test files, it is helpful to redirect stdout to
#    /dev/null and then redirect stderr to more.  That is done
#    like this: ./espmerge.sh bigtest.yaml 2>&1 >/dev/null | more
#    and that works because the shell does redirections from right to left.

# 3. dbgParse can be set to one to see how blocks are found.
#    dbgMerge can be set to one to see how blocks are stored and output.

# FWIW, this script does not use any subprocesses and runs entirely in bash.

# Globals

declare -r me=${0##*/}  # basename of this script
declare retval		# optional return value of a function
declare -i nlines=0	# number of yaml lines input 
declare -i _nlines=0	# number of digits in nlines variable (e.g 2 for 64)
declare -i nmapkeys=0	# monotonically incrementing map key number

declare -a    lines	    # array of all input lines

# These arrays are indexed by line number up to <nlines>.

declare -a -i skip	    # flags inidctating lines should not be output
declare -a -i visited	    # flags lines visited during BFS to avoid loops
declare -a block_list	    # a string of block indices to append to lines

# This associative arrays is indexed by the key of the block 
# which is <mapkey>/<item>/..  where item can be an array
# item name, an item name or id: tag.

declare -A -i key_block     # the block number of a key if seen, or unset

# These are used by the front-end parser to store information on all
# the common blocks. They are set by scanning each map key in sequence
# using breadth first search. The numeric arrays are indexed by block
# number.

declare -i nblocks=0	    # block number

declare -a    block_key	    # assigned block key (/mapkey:/item:/item:/etc...
declare -a -i block_from    # block first line number
declare -a -i block_to      # block last line number
declare -a -i block_idline  # block "id:" line if it has one, else zero

# These read-only strings are used to identify special esphome yaml lines.

declare -r newdoc="---"
declare -r is_array='^[[:blank:]]*- ([[:alnum:]: _]+)[[:blank:]]*$'
declare -r is_id='^[[:blank:]]+id:[[:blank:]]+([[:alnum:]_]+)[[:blank:]]*$'
declare -r is_key='^[[:blank:]]*([[:alnum:]_]+):[[:blank:]]*$'
declare -r is_mapkey='^([[:alnum:]_]+:)[[:blank:]]*$|^---$'
declare -r is_comment='^[[:blank:]]*#.*$'
declare -r is_blank='^[[:blank:]]*$'
declare -r get_mapname='^([[:alnum:]_]+):.*$'

# This function reads in esphome yaml on stdin.

read_lines () {
  declare -i n=0

  # Read in the whole yaml file and mark any document separators
  # and comments to not be output.

  while IFS='' read -r lines[$n]
  do
    skip[$n]=0
    visited[$n]=0
    block_list[$n]=""
    if [[ "${lines[$n]}" == "$newdoc" ]]; then
      skip[$n]=1
    fi
    if [[ "${lines[$n]}" =~ $is_comment ]]; then
      skip[$n]=1
    fi
    if [[ "${lines[$n]}" =~ $is_blank ]]; then
      skip[$n]=1
    fi
    n=n+1
  done

  nlines=$n		# number of lines of yaml 
  _nlines=${#nlines}	# number of digits in nlines
}

# Worker function that outputs lines and marks them for skipping.

_write_lines () {
  declare -i n=$1	# line number
  declare -i oldline=$2	# merging from line, or zero

  declare -a -i blocks=(${block_list[$n]})
  declare -i nblocks=${#blocks[@]}

  declare -i bl # block_list index
  declare -i b  # block index
  declare -i p  # column indentation alignment for merge comment

  if ((skip[$n] == 1)); then
    return;
  fi

  # Output line $n.

  if ((oldline==0)); then
    echo "${lines[$n]}"
  else

    # Round comment column to next highest x10 after yaml line, min 40.

    p=(${#lines[$n]}/10+1)*10
    ((p<=40)) && p=40
    printf "%-*s # espmerge.sh: was line $((oldline+1))\n" $p "${lines[$n]}"
  fi

  skip[$n]=1		# a line can only be output once

  # Output the lines of any blocks appended to line $n while outputting
  # any blocks appended to their lines, in the process.

  for ((bl=0; bl < nblocks; bl=bl+1 )); do
    b=blocks[bl]
    for ((l=${block_from[$b]}; l <= ${block_to[$b]}; l=l+1 )); do
      _write_lines $l $l
    done
  done
}

# Output the input, while merging.

write_lines () {
  declare -i n=0

  for ((n=0; n<nlines; n=n+1)); do
    _write_lines $n 0
  done
}

# _record_work saves blocks in an associative array index by the block key.

# Before it saves the block it checks if it already exists.
# If it does, then the block has already been seen and it is recorded
# as merge work. In other words, duplicate common blocks become merge work.
# _record_work considers array items, since duplicate array items are
# permitted and so they do not become merge work. However, if a duplicate
# array is named by an id:, then it can become work.  That is why array
# items have id: in their key, if specified.

_record_work () {
  declare -i block="$1"

  declare key="${block_key[$block]}"
  declare -i from=${block_from[$block]}
  declare -i to=${block_to[$block]}
  declare -i idline=${block_idline[$block]}

  declare -i n=0	# utility integer variable
  declare -i kb=0	# key block number
  declare -i dest	# where to merge to
  declare id=""		# <tag> of "id: <tag>" line

  [[ "${lines[$idline]}" =~ $is_id ]]
  id="${BASH_REMATCH[1]}"		# grab <id> from "id: <id>"

  # If the key has never been seen, save it and return.

  if [ -z "${key_block[$key]:-}" ]; then
    ((dbgMerge)) && echo \
      "*** Saved block $((block+1)) $((from+1))-$((to+1)) ($id)" >&2
    key_block[$key]=$block
    return
  fi

  # This is the second time we see this block. Merge it.

  kb=${key_block[$key]}
  dest=${block_to[$kb]}

  ((dbgMerge)) && echo \
      "*** Found block $((kb+1)) for block $((block+1)) $((from+1))-$((to+1)) ($id)" >&2

  ((chatty)) && echo \
  "$me: Moving lines $((from+1))-$((to+1)) to line $((dest+1)) (id: $id)" >&2

  # Skip the id: line since it is in the block being merged into.

  skip[$idline]=1

  ((dbgMerge)) && echo "*** Skipping id line $((idline+1)) (id: $id)" >&2

  # If we are merging an array elemeny, we will skip the from line too.

  if [[ "${lines[$from]}" =~ $is_array ]]; then
    ((dbgMerge)) && ((skip[from]==0)) && echo \
	"*** Skipping array line $((from+1))" >&2
    skip[$from]=1
  fi

  # Record the merge work by appending the block number to the dest line.

  block_list[$dest]="${block_list[$dest]} $b"

  # Skip the leading up section headers in the merged section since
  # they will come from the destination block being merged into.

  n=from-1

  while (( n>= 0 )); do
    if ((dbgMerge==1 && skip[n]==0)); then
      if [[ "${lines[$n]}" =~ $is_key ]]; then
        id="${BASH_REMATCH[1]}"	
        echo "*** Skipping key line $((n+1)) ($id)" >&2
      else
        echo "*** Skipping line $((n+1))" >&2
      fi
    fi;
    skip[$n]=1
    if [[ "${lines[$n]}" =~ $is_mapkey ]]; then
      break;
    fi
    n=n-1
  done
}

# Debug function for when dbgParse is set to 1.

dump_common_block () {
  declare -r -i b=$1
  declare -i l

  echo "*** Block $((b+1)) ($key)" >&2
  for ((l=block_from[b]; l <= block_to[b]; l=l+1)); do
    echo " $((l+1)): ${lines[$l]}" >&2
  done
}

# Debug function currently not called.

dump_common_blocks () {
  declare -i b;

  for ((b=0; b < nblocks; b=b+1)); do
    dump_common_block $b
  done
}

# Get the previous line that is not skipped (i.e. not a --- or comment).

_get_prev_non_skip () {
  declare -i n=$1

  n=n-1
  while ((n >= 0)); do
    if ((skip[$n] == 0)); then
      retval=$n;
      return
    fi
    n=n-1
  done
  retval=-1
}

# Get the next line that is not skipped.

_get_next_non_skip () {
  declare -i n=$1

  n=n+1
  while ((n < nlines)); do
    if ((skip[$n] == 0)); then
      retval=$n
      return;
    fi
    n=n+1
  done
  retval=$nlines
}

# Get the first line in the file that is not skipped.

_get_first_non_skip () {
  _get_next_non_skip -1
}

# Get the number of spaces before the first non-space character in the line.

_get_indentation () {
  declare -i n=$1
  declare spaces=""
  
  spaces="${lines[$n]%%[![:space:]]*}"
  if [[ "${lines[$n]}" =~ $is_array ]]; then
    spaces="$spaces  "
  fi
  retval="$spaces"
}

# Get the last line number of a common block.

_get_block_to () {
  declare -i n=$1		# first line of the block
  declare -i spanItems=$2	# include all items if its an array

  declare skipSpaces
  declare lineSpaces

  _get_indentation $n; skipSpaces="$retval"
  _get_next_non_skip $n; n=$retval

  while (( n<= nlines)); do
    _get_indentation $n; lineSpaces="$retval"

    if [[ "$lineSpaces" < "$skipSpaces" ]]; then
      break;
    fi
    if [[ "$spanItems" == "0" && "$lineSpaces" == "$skipSpaces" && \
	  "${lines[$n]}" =~ $is_array ]]; then
      break;
    fi
    _get_next_non_skip $n; n=$retval
  done

  _get_prev_non_skip $n

  # retval from _get_prev_non_skip passed back through to caller
}

# _find_blocks(): Find all the common blocks in a block.

# A common block starts at a mapkey or when indentation moves right and
# ends at a next mapkey or when indentation moves left. Each array element
# is also a common blocks. Array elements start with "- " and end at a
# next "- " or when when indentation moves left. Note that "- " is
# considered "  " by _get_indentation() for indentation comparisons.

# If this was a depth-first seach, below would simply recurse. However,
# this is breadth-first search in order to retain ordering so _find_blocks()
# uses a queue to record blocks in the order of their start line.

_find_blocks() {
  declare -i -r first=$1   # first line of the block to search in
  declare -i -r last=$2	   # last line of the block to search in
  declare key="$3"	   # key for this block
  declare idTag="$4"	   # default "id:" for this block

  declare -i n
  declare -i q
  declare -i prev=0
  declare -i idline=0

  declare blockSpaces=""
  declare lineSpaces=""
  declare skipSpaces=""

  declare -i nqueue=0	    # number of blocks found inside this one
  declare -i -a queue_first # array of first lines of each inside block
  declare -i -a queue_last  # array of last  lines of each inside block
  declare -a queue_idTag    # default id:'s for each inside block

  _get_indentation "$first"; blockSpaces="$retval"

  ((dbgParse)) && echo \
    "*** Start _find_block $((first+1)) $((last+1)) \"$key\" \"$idTag\"" >&2

  n=$first

  while (( n <= last )); do

    _get_indentation $n; lineSpaces="$retval"

    # If we are at a next mapkey, end the current block.
    if (( n>first )); then
      if [[ "${lines[$n]}" =~ $is_mapkey ]]; then
        break
      fi
    fi

    # If indentation goes left, end the current block.

    if [[ "$lineSpaces" < "$blockSpaces" ]]; then
      ((dbgParse)) && echo "***: Indentation went left"
      break
    fi

    # If indentation goes right, queue the inside block.

    if [[ "$lineSpaces" > "$blockSpaces" ]]; then
      queue_first[$nqueue]=$n
      # if mapkey, use default tag "id: <null>". Else use the previous line
      if [[ "$blockSpaces" == "" ]]; then
        queue_idTag[$nqueue]="id: <none>"
      else
        _get_prev_non_skip $n; prev=$retval
        queue_idTag[$nqueue]="${lines[$prev]}"
      fi
      _get_block_to $n 1; n=$retval
      queue_last[$nqueue]=$n

      ((dbgParse)) && echo \
        "*** Indentation went right $((queue_first[$nqueue]+1)) $((n+1))" >&2

      nqueue=nqueue+1

      _get_next_non_skip $n; n=$retval
      continue
    fi

    # From here, the line is in the current block.

    # If this is the beginning of a list of array items, queue them each
    # for scanning one item at a time as a block since they may have
    # sub-blocks and also they may have an id: field to qualify it's key

    if [[ "${visited[$n]}" == "0" && "${lines[$n]}" =~ $is_array ]]; then
      visited[$n]=1
      queue_first[$nqueue]=$n
      queue_idTag[$nqueue]="${lines[$n]}"
      _get_block_to $n 0; n=$retval
      queue_last[$nqueue]=$n

      ((dbgParse)) && echo \
	"*** Queued block $((queue_first[$nqueue]+1)) $((n+1))" >&2

      nqueue=nqueue+1

      _get_next_non_skip $n; n=$retval
      continue
    fi

    # If it has an id: line, record that in idLine

    if [[ "${lines[$n]}" =~ $is_id ]]; then
      idline=$n
      ((dbgParse)) && echo "*** Parsed ${BASH_REMATCH[1]} id at $((n+1))" >&2
      idTag="${BASH_REMATCH[1]}"
    fi
    
    ((dbgParse)) && echo "*** Queued line $((n+1))" >&2

    _get_next_non_skip $n; n=$retval
  done

  if [[ "$idTag" != "" ]]; then
    key="$key/$idTag"
  fi

  if ((idline != 0)); then
    _get_prev_non_skip $n;
    block_from[$nblocks]=$first
    block_to[$nblocks]=$retval
    block_idline[$nblocks]=idline
    block_key[$nblocks]="$key"

    ((dbgParse)) && \
	  dump_common_block $nblocks

    nblocks=nblocks+1
  fi

  # Now handle any queued blocks.

  for ((q=0; q < nqueue; q=q+1)); do
    _find_blocks ${queue_first[$q]} ${queue_last[$q]} \
		 "$key" "${queue_idTag[$q]}"
  done

  ((dbgParse)) && echo \
    "*** End _find_block $((first+1)) $((last+1)) \"$key\" \"${idTag}\"" >&2

  retval=$n
}

# Kick off _find_blocks() starting at each mapkey.

find_blocks() {
  declare -i n=0
  declare key=""

  _get_first_non_skip; n=$retval

  while ((n < nlines)); do
    if [[ "${lines[$n]}" =~ $is_mapkey ]]; then
      [[ "${lines[$n]}" =~ $get_mapname ]]
      key="/${BASH_REMATCH[1]}"
      nmapkeys=nmapkeys+1
      _find_blocks $n $((nlines-1)) "$key" ""
      n=$retval
    else
      echo "$me: Error: line $((n+1)) is not a map key: ${lines[$n]}"
      exit -1
    fi
  done 
}

# For each block found by find_blocks(), check for merge blocks.

record_work () {
  declare -i b;

  for ((b=0; b < nblocks; b=b+1)); do
    _record_work "$b"
  done
}

main () {

  read_lines	# Read stdin into the 'lines' array.

  find_blocks	# Find common blocks in 'lines' using breadth first search.

  record_work	# Scan the blocks and identify merge 'work'.

  write_lines	# Write the 'lines' array out while processing work.

  exit 0	# Done. Voila!
}

main;		# main() never returns.

