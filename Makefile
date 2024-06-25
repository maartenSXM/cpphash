# Copy this Makefile to any directory that you want to use cpptext
# with. This Makefile will clone cpptext so that its Makefile fragments
# can be included.
#
# "make" will install cpptext under OUTDIR once. Afterwards, it will
# revert to "make all" as defined in cpptext/Makefile.cpptext.
# Note that if your project is for esphome, you may want to
# uncomment the include below (see *** below).
#
# "make update" will update cpptext from github.
#
# Refer to github.com/maartenwrs/cpptext for more details on cpptext.

# Makefile.cpptext can be customized using these variables:
MAIN	:= main.yaml
SUFFIX	:= $(suffix $(MAIN))
SRCS	:= $(wildcard *$(SUFFIX))
OUTDIR	:= .
PREFIX	:= myProj_
PROJTAG	:= 0

# Advanced: Refer to cpptext/Makefile.cpptext for details as to how
# the BUILD, CLEAN and REALCLEAN variables are used, before defining them.
# BUILD	    := @/bin/true
# CLEAN	    := @/bin/true
# REALCLEAN := @/bin/true

-include $(OUTDIR)/cpptext/Makefile.cpptext

# *** uncomment the following line if using cpptext in an esphome project
# -include $(OUTDIR)/cpptext/Makefile.esphome

# if $(OUTDIR)/cpptext exists, update it with "git pull" - else "git clone" it
$(OUTDIR)/cpptext update:
	-@mkdir -p $(OUTDIR)
	-@if [ -d "$(OUTDIR)/cpptext" ]; then 					\
		echo "Updating git repo $(OUTDIR)/cpptext";			\
		cd $(OUTDIR)/cpptext; git pull; 				\
	else									\
		echo "Cloning git repo $(OUTDIR)/cpptext";			\
		cd $(OUTDIR); git clone git@github.com:maartenwrs/cpptext;	\
	fi
	make

.PHONY: update
