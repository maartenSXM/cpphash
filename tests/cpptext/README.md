# test

Makefile that tests dehash via cpptest/examples/make

## Makefile

The Makefile in this directory generates the ../make example esphome
yaml file using ../make/Makefile which runs dehash.  It then compares
the generated yaml against the original espmake.yaml file that does not
use the C-preprocessor directives.  It does the comparison by running
two espmake.yaml configurations through the command "esphome config"
and diffing the output.  It prints test passed or failed.

To run the test, type 'make'. Thank you for the example Landon!
