# Copy this Makefile to any directory that you want to use cpptext
# with. This Makefile will clone cpptext so that its Makefile fragments
# can be included.
#
# "make" will install cpptext under OUTDIR once. Afterwards, it will
# revert to "make all" as defined in cpptext/Makefile.cpptext.
#
# This project resides at github.com/maartensxm/cpptext 

MAIN	:= main.yaml
SUFFIX	:= $(suffix $(MAIN))
SRCS	:= $(wildcard *$(SUFFIX))
OUTDIR	:= .
PREFIX	:= myProj_
PROJTAG	:= 0

# Advanced: see how cpptext/Makefile.cpptext uses thse
# Makefile.esphome is an example of their use.
# BUILD	    := @/bin/true
# CLEAN	    := @/bin/true
# REALCLEAN := @/bin/true

-include $(OUTDIR)/cpptext/Makefile.cpptext

# uncomment the include of Makefile.esphome for esphome projects
# -include $(OUTDIR)/cpptext/Makefile.esphome

$(OUTDIR)/cpptext:
	-@mkdir -p $(OUTDIR)
	git -C $(OUTDIR) clone git@github.com:maartenwrs/cpptext
	$(MAKE) --no-print-directory
