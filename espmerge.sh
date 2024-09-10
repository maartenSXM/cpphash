#!/bin/bash 

me=$(basename "$0")

# merge esphome yaml array elements named by an "id:" item

verbose=0
chatty=1

declare -A id_from
declare -A id_to

is_newdoc='---'
is_array='^[[:blank:]]+- .+$'
is_id='^[[:blank:]]+id:[[:blank:]]+(.+)$'
nwork=0

# slurp in the yaml on stdin

read_lines () {
  local n=0
  while IFS='' read -r lines[$n]
  do
    let "n=n+1"
  done

  let "nlines=n"
}

# burp out the merged yaml on stdout

write_lines () {
  local w=0
  local n=0
  local i=0
  local dest=0
  local to=0

  # for each block of merge work to do

  for (( w=0 ;   w < $nwork  ; w++ )); do

    # output the original lines up to the work, unless skipping them
    for (( dest=work_dest[w]; n <= dest; n++ )); do
      (( skip[n] == 0 )) && echo "${lines[$n]}"
    done

    # skip first line of replicated section to merge
    i=${work_from[$w]}+1
    for (( to=work_to[w]; i <= to; i++ )); do
      # skip id: since already specified
      if [[ ! "${lines[$i]}" =~ $is_id ]]; then
        echo "${lines[$i]}"
      fi
    done
  done

  # now out the rest of the non-merged lines, unless skipping them
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
      ((chatty)) && \
		echo "$me: merging lines ${from}-$to to $lookup_to for $id" >&2
      work_from[$nwork]=$from
      work_to[$nwork]=$to
      work_dest[$nwork]=$lookup_to
      let "nwork++"
      for (( n=from; n <= to; n++ )); do
        # record that we have to skip outputting these lines since they
	# are outputting earlier in the file due to merge
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

     # get the leading spaces of the current line
     spaces="${lines[$n]%%[![:space:]]*}"

     # add 2 to space if it is an array element to consider "- "
     if [[ "${lines[$n]}" =~ $is_array ]]; then
       spaces="$spaces  "
     fi

     # if depth if less than where we started, we are at the end of the block
     if [[ "$spaces" < "$startSpaces" ]]; then
       break
     fi

     # new array is starting, start a new block and then end this one
     if [[ "${lines[$n]}" =~ $is_array ]]; then
       if [[ "$blockIsArray" == "1" ]]; then
         ((verbose)) && echo in array at $n "x${spaces}x"
         _find_id_block "$n"
         n=$ret_n
         ((verbose)) && echo out array at $n
         break;
       fi
     fi

     # indentation went to the right, start a new block
     if [[ "$spaces" > "$startSpaces" ]]; then
       ((verbose)) && echo in block at $n "x${spaces}x"
       _find_id_block "$n"
       n=$ret_n
       ((verbose)) && echo out block at $n
       continue
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

record_block_moves () {
  true
}

status=0

read_lines

find_id_blocks

record_block_moves

write_lines

exit $status

# cp esphome.yaml smeg.yaml
# yq '... comments=""' smeg.yaml >smeg2.yaml
# awk '/^[[:alnum:]_]/{print "---"}; {print $0}' <smeg2.yaml >smeg3.yaml
# yq -eval-all -P smeg3.yaml >smeg4.yaml

# echo "smeg: ${keys[switch:]}"
for i in "${!keys[@]}"
do
  # echo "${i}=${keys[$i]}"
  echo "${i}"
done
