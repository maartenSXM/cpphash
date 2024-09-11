#!/bin/bash

me=$(basename "$0")

# merge esphome yaml array elements named by an "id:" item

# Array blocks to merge must be fully qualified and only
# have items at the lowest level.  The id: must only
# refer to the level that the items will merge into.

#
# This block comment contains a *valid* input:
#

: <<'END'
---
touchscreen:
  - platform: cst226
    id: gosBsp_touchscreen
    interrupt_pin: 8
---
display:
  platform: qspi_amoled
  id: gosBsp_display
  model: RM690B0
---
touchscreen:
  - platform: cst226
    id: gosBsp_touchscreen
    reset_pin: 17
END

#
# This block comment contains an *invalid* input:
#

: <<'END'
---
touchscreen:
  - platform: cst226
    id: gosBsp_touchscreen
    - platform: foo
      id: gosBsp_foo
      item2: glorp
---
foo:
  id: gosBsp_display
---
touchscreen:
  - platform: cst226
    id: gosBsp_touchscreen
    - platform: foo
      id: gosBsp_foo
      item2: blort
END

verbose=0
chatty=0

declare nlines=0	# number of input lines read 
declare nwork=0		# number of work items (line blocks) to merge

# skip array is indexed by input line number 0 to <nlines>

declare -a skip		# lines to not output

# These arrays are indexed by work item number 0 to <nwork>

declare -a work_from	# first line of merge block
declare -a work_to	# last line of merge block
declare -a work_dest	# line number of where to merge to

# These associative arrays are indexed by esphome id: (text)

declare -A id_from	# begin of recorded merge block
declare -A id_to	# destination of recorded merge block
declare -A id_spaces	# indentation level of recorded merge block

# These strings used to identify special esphome yaml lines

declare is_newdoc='---'
declare is_array='^[[:blank:]]+- .+$'
declare is_id='^[[:blank:]]+id:[[:blank:]]+(.+)$'

# This function reads in the esphome yaml on stdin

# It is advised to preprocess the esphome yaml with
# yq '... comments=""' esphome.yaml | awk '/^[[:alnum:]_]/{print "---"}
# before piping it into espmerge.yaml.  See yamlmerge.sh which invokes
# espmerge.sh and also esphome.mk which invokes yamlmerge.sh.

read_lines () {
  local n=0
  while IFS='' read -r lines[$n]
  do
    let "n=n+1"
  done

  let "nlines=n"
}

# Output the merged yaml on stdout. Works on globals declared above

write_lines () {
  local w=0
  local n=0
  local i=0
  local dest=0
  local to=0

  # While outputting yaml, process the merging work items recorded

  for (( w=0 ;   w < $nwork  ; w++ )); do

    # Output the original lines up to the work, unless skipping them
    for (( dest=work_dest[w]; n <= dest; n++ )); do
      (( skip[n] == 0 )) && echo "${lines[$n]}"
    done

    # Skip first line of the merge block as it is already in the dest block

    i=${work_from[$w]}+1
    for (( to=work_to[w]; i <= to; i++ )); do
      # skip the id: since already specified
      if [[ ! "${lines[$i]}" =~ $is_id ]]; then
        echo "${lines[$i]}"
      fi
    done
  done

  # Output the rest of the lines of input after all work items are done

  while (( n < $nlines )); do
    (( skip[n] == 0 )) && echo "${lines[$n]}"
    let "n++"
  done
}

# Record the block to merge as long as it is at the same indentation level.
# Else it is a reference to an id that is in another array element.

# The corollary is that this script will fail if there is a back
# reference to an existing array element by id: from a different array
# element at the same indentation level.

id_record () {
  local from="$1"
  local to="$2"
  local idLine="$3"
  local id="$4"
  local spaces="$5"
  local lookup_to=${id_to[$id]}
  local n

  if [[ $lookup_to == "" ]]; then
    id_from[$id]="$from"
    id_to[$id]="$to"
    id_spaces[$id]="$spaces"
  else
    if [[ "${id_spaces[$id]}" == "$spaces" ]]; then
      echo "$me: merging lines ${from}-$to to $lookup_to for $id" >&2
      work_from[$nwork]=$from
      work_to[$nwork]=$to
      work_dest[$nwork]=$lookup_to
      let "nwork++"
      for (( n=from; n <= to; n++ )); do
        # record that we have to skip outputting these lines since they
	# are outputting earlier in the file due to being in a merge block
        skip[$n]=1
      done
      # also skip the leading up section headers in the merged section since
      # since they will come from the destination block being merged into
      (( n=from-1 ))
      while [[ "${lines[$n]}" != "---" ]]; do
        skip[$n]=1
	let "n--"
      done
      skip[$n]=1
    else
      ((chatty)) && \
		echo "$me: ignoring line $idLine back-reference to $id" >&2
    fi
  fi
}

# This function is called recursively for each common block of yaml

_find_id_block () {
  local blockStart="$1"

  local n
  local startSpaces

  local blockIsArray="0"
  local blockHasId="0"
  local spaces=""
  local id
  local idLine

  startSpaces="${lines[$blockStart]%%[![:space:]]*}"

  if [[ "${lines[$blockStart]}" =~ $is_id ]]; then
     blockHasId="1"
     id=${BASH_REMATCH[1]}
     idLine=$blockStart
  fi

  if [[ "${lines[$blockStart]}" =~ $is_array ]]; then
     blockIsArray="1"
     startSpaces="$startSpaces  "
  fi

  let "n=blockStart+1"

  while (( n < nlines )); do

     # Get the leading spaces of the current line

     spaces="${lines[$n]%%[![:space:]]*}"

     # Add 2 to spaces if it is an array element in order to consider "- "

     if [[ "${lines[$n]}" =~ $is_array ]]; then
       spaces="$spaces  "
     fi

     # If depth is less than where we started, we are at the end of the block

     if [[ "$spaces" < "$startSpaces" ]]; then
       break
     fi

     # A New array item is starting: start a new block and then end this one
     if [[ "${lines[$n]}" =~ $is_array ]]; then
       if [[ "$blockIsArray" == "1" ]]; then
         ((verbose)) && echo in array at $n "x${spaces}x"
         _find_id_block "$n"
         n=$ret_n
         ((verbose)) && echo out array at $n
         break;
       fi
     fi

     # Indentation went to the right: start a new block
     if [[ "$spaces" > "$startSpaces" ]]; then
       ((verbose)) && echo in block at $n "x${spaces}x"
       _find_id_block "$n"
       n=$ret_n
       ((verbose)) && echo out block at $n
       continue	    # since there could be more lines in this common block
     fi

     # correct depth: this line is in the block

     # Record whether the block has an "id:" field

     if [[ "${lines[$n]}" =~ $is_id ]]; then
       blockHasId="1"
       id=${BASH_REMATCH[1]}
       idLine=$n
     fi

     let "n=n+1"
  done

  ret_n="$n"

  let "n--"

  # If block has an id: field, let's remember it
  
  if [[ "$blockHasId" == "1" ]]; then
    id_record $blockStart $n "$idLine" "$id" "$startSpaces"
  fi

  ((verbose==0)) && return

  if [[ "$blockHasId" == "1" ]]; then
    echo "*** id block:     $blockStart-$n with key $id"
  else
    if [[ "$blockIsArray" == "1" ]]; then
      ((verbose)) && echo "*** array block:  $blockStart-$n"
    else
      ((verbose)) && echo "*** normal block: $blockStart-$n"
    fi
  fi
}

find_id_blocks () {
  _find_id_block 0
}

read_lines

find_id_blocks

write_lines

exit 0

