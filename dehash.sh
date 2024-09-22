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

declare -r usage="`basename $0`: strip hash-style comments

Usage: `basename $0` [-c] [-b] [-h] file\n
  -c|--cpp\tkeep CPP directives.
  -b|--blank\tkeep blank lines.
  -o|--out)\toutfile file (or - for stdout)
  -h|--help\thelp.
<file> is the file to dehash to stout (or - for stdin).

This script is from git repo github.com/maartenSXM/cpphash.
Note: this script does not vet arguments securely. Do not setuid or host it.
"

while [[ $# > 0 ]]
do
  case $1 in
    -c|--cpp)	GCCFLAGS="$GCCFLAGS -DCPP"; shift;;
    -o|--out)	outfile="$2"; shift 2;;
    -b|--blank)	GCCFLAGS="$GCCFLAGS -DBLANK"; shift;; 
    -h|--help)	printf "$usage"; exit 0;;
    *) break
  esac
done

GCC="gcc -x c -C -undef -nostdinc -E -P -Wno-endif-labels -Wundef -Werror -"

file="$1"
if [ "$file" == "" ]; then
  file=/dev/stdin
fi

if [ "$outfile" == "" ]; then
  outfile=/dev/stdout
else
  if [ "$outfile" == "-" ]; then
    outfile=/dev/stdout
  fi
fi

# The following sed script is based on the code in the comment from anonymous
# user user218374 found here: 
#  https://unix.stackexchange.com/questions/383960/sed-stripping-comments-inline/766997
# Thank you! :-)

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

# This adds or removes code from the sed script by piping it through
# the C preprocessor based on the flags specified.

echo '
  #ifndef CPP

    # // If not planning to run output through cpp, line 1 shebang can stay.
    1 {/^#!/p}

  #else // CPP

    # // Else, change it to __SHEBANG__ and caller must change it back
    # // later with, for example this sed: 1 {s,^__SHEBANG__,#!}.
    1 {s,^#!,__SHEBANG__,}

    # // Concatenate lines ending in backslash for further processing below.
    # // This will handle multi-line comments and multi-line cpp directives.
    :x; /\\\s*$/ { N; s/\\\n//; tx }

    # // Map "#default X no" to "#ifndef X \n#define X 0\n#endif\n"
    {s@^\s*#\s*default\s\s*([a-zA-Z0-9_][a-zA-Z0-9_]*)(\s\s*no)($|\s.*$)@//#default \1\2\3\n#   ifndef \1\n#   define \1 0\n#   endif@}

    # // Map "#default X yes" to "#ifndef X \n#define X 1\n#endif\n"
    {s@^\s*#\s*default\s\s*([a-zA-Z0-9_][a-zA-Z0-9_]*)(\s\s*yes)($|\s.*$)@//#default \1\2\3\n#   ifndef \1\n#   define \1 1\n#   endif@}

    # // Map "#default X Y" to "#ifndef X \n#define X Y\n#endif\n"
    {s@^\s*#\s*default\s\s*([a-zA-Z0-9_][a-zA-Z0-9_]*)(\s\s*)(.*)$@//#default \1\2\3\n#   ifndef \1\n#   define \1\t\3\n#   endif@}

    # // Map "#default X" to "#ifndef X \n#define X\n#endif\n"
    # // Not recommended in general since #ifdef X is legit code without
    # // a #default. Use "#default X yes" with "#if X" instead to catch
    # // missing #defaults and typos in #if or #default statements.
    {s@^\s*#\s*default\s\s*([a-zA-Z0-9_][a-zA-Z0-9_]*)(.*)$@//#default \1\2\n#   ifndef \1\n#   define \1\n#   endif@}

    # // Map "#redefine X Y" to "#undef X \n#define X Y\n"
    {s@^\s*#\s*redefine\s\s*([a-zA-Z0-9_][a-zA-Z0-9_]*)(\s\s*)(.*)$@//#redefine \1\2\3\n#   undef   \1\n#   define  \1 \3@}

    # // Done expanding #default or #redefine, go to next line
    /^\/\/#(default|redefine) /b

    # // Keep cpp directive lines, go to next line
    /^\s*#\s*(assert\s|define\s|elif\s|else|endif|error|ident\s|if\s|ifdef\s|ifndef\s|import\s|include\s|include_next\s|line\s|pragma\s|sccs\s|unassert\s|undef\s|warning)/b

    # // Keep C comment lines starting with // that have a hash
    /^\s*\/\/.*#/b
  #endif // CPP
  
  # // Delete lines starting with #
  /^[\t\ ]*#/d

  #ifndef BLANK

    # // Delete blank lines
    /\S/!d

  #endif // !BLANK
  '"
  /(^|\s)$double_quotes_open/{:a;N;ba;}
  /(^|\s)$single_quotes_open/{:b;N;bb;}
  /$B$d/{:c;N;bc;}
  s,\s*#.*|($quoted_word|.|$b$d#|$B#),\1,g
  "'
  #ifndef BLANK

    # // Delete blank lines
    /\S/!d

  #endif // !BLANK

' | $GCC $GCCFLAGS | $SED -E -r -f - "$file" > "$outfile"

exit $?
