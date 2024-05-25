#!/bin/bash

HELP="$0 removes '#'-style comments\nUsage: $0 [-c] [-b] [-h] filename\n-c|--cpp\tkeep CPP directives\n-b|--blank\tkeep blank lines\n-h|--help\thelp\nfile\t file to dehash to stout or - for stdin"

while [[ $# > 0 ]]
do
  case $1 in
    -c|--cpp)	GCCFLAGS="$GCCFLAGS -DCPP"; shift;;
    -o|--output) shift 2;;  # deprecated
    -b|--blank)	GCCFLAGS="$GCCFLAGS -DBLANK"; shift;; 
    -h|--help)	echo -e "$HELP"; shift;; 
    *) break
  esac
done

GCC="gcc -x c -C -undef -nostdinc -E -P -Wno-endif-labels -Wundef -Werror -"

file="$1"
if [ "$file" == "" ]; then
  file=/dev/stdin
fi

# The following sed script is based on https://unix.stackexchange.com/questions/383960/sed-stripping-comments-inline/766997#766997

# q=quote, Q=doubleQuote, d=dollarSign
q=\\x27 Q=\\x22 d=\\x24
# b=backslash, B=doubleBackslash, e=exclamationMark
b=\\x5c B=\\x5c\\x5c e=\\x21

# construct regexes using symbolic names
single_quotes_open="$q[^$b$q]*($B.[^$b$q]*)*$d"
single_quoted_word="$q[^$b$q]*($B.[^$b$q]*)*$q"
double_quotes_open="$Q[^$b$Q]*($B.[^$b$Q]*)*$d"
double_quoted_word="$Q[^$b$Q]*($B.[^$b$Q]*)*$Q"
quoted_word="$double_quoted_word|$single_quoted_word"


echo '
  #ifndef CPP
    # // if not planning to run output through cpp, line 1 shebang can stay
    1 {/^#!/p}
  #else // CPP
    # // else change it to __SHEBANG__ and caller must change it back
    # // later with, for example this sed: 1 {s,^__SHEBANG__,#!}
    1 {s,^#!,__SHEBANG__,}
    # // keep cpp directive lines (b=branch next line)
    /^\s*#\s*\(assert\s|define\s|elif\s|else|endif|error|ident\s|if\s|ifdef\s|ifndef\s|import\s|include\s|include_next\s|line\s|pragma\s|sccs\s|unassert\s|undef\s|warning\)/b
  #endif // CPP
  #
  # // delete lines starting with #
  /^[\t\ ]*#/d

  #ifndef BLANK
    # // delete blank lines
    /\S/!d
  #endif // !BLANK
  '"
  /(^|\s)$double_quotes_open/{:a;N;ba;}
  /(^|\s)$single_quotes_open/{:b;N;bb;}
  /$B$d/{:c;N;bc;}
  s,\s*#.*|($quoted_word|.|$b$d#|$B#),\1,g
  "'
  #ifndef BLANK
    # // delete blank lines
    /\S/!d
  #endif // !BLANK
' | $GCC $GCCFLAGS | sed -E -f - $file

exit $?
