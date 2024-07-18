# This file, "./makefile", and "./Makefile" are based on examples from:
#
#       github.com/maartenSXM/cpptext
#
# This makefile automatically installs cpptext and then includes "./Makefile"

# Disable built-in rules and variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKECMDGOALS ?= all

OUTDIR := .

ifeq (,$(wildcard $(OUTDIR)/cpptext))
    ifeq (1,$(BAIL))
        $(error "$(firstword $(MAKEFILE_LIST)): Loop detected. Bailing out.")
    endif

$(MAKECMDGOALS): 
	mkdir -p $(OUTDIR)
	git -C $(OUTDIR) clone git@github.com:maartenSXM/cpptext
	$(MAKE) BAIL=1 --no-print-directory $(MAKECMDGOALS)
else
    include Makefile
endif

