# CLI examples 

Below are some valid dehash.sh and cpptext.sh invocations that can be run from
the shell in this directory.  The help option -h explains what each does and
is also provided in the README file in the top of this repo.

## dehash.sh
```
 ../../dehash.sh -h
 ../../dehash.sh example.txt
 ../../dehash.sh -b example.txt
 ../../dehash.sh -c -b example.txt
```

## cpptext.sh
```
 ../../cpptext.sh -h
 ../../cpptext.sh -o - example.txt
 ../../cpptext.sh -b -D foo -o - example.txt
 ../../cpptext.sh -C
```

# NOTE
On MacOS, you need GNU sed to run dehash.sh and cpptext.sh.
To install GNU sed, please do this:
```
brew install gsed
```
and then either issue this line in the shell or add this line to
~/.bashrc and source ~/.bashrc:
```
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
```

