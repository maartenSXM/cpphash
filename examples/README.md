# Examples

subdirectories containing some example and text commands

## cli

The cli directory README domenstrates command line invocations of 
dehash.sh and cpptext.sh.  It contains a text file containing some lines
that have hashes in them which need to be parsed in different ways.

## make

The make directory contains an example of an project that
uses a Makefile to generate multiple project variants from the same
yaml files using dehash and the C preprocessor.  It can be used
as a template for any project using text files.

## test

The test directory compares the output of the make example to the
original project that did not use make, dehash and the C-preprocessor.
It achieves it's goal by running the generated yaml and the original
yaml both through the esphome configuration validation tool, and thus
requires that it the esphome command is installed.


