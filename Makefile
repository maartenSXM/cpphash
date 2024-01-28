# Copy this Makefile to any directory that you want to use cpptext
# with. This Makefile will install cpptext under that directory
# and you can then use make to build your text files with c preprocessor
# directive features.
#
# "make" will install cpptext under OUTDIR once. Aftewards, it will
# revert to "make all" of cpptext/Makefile.cpptext.
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

# if $(OUTDIR)/cpptext exists, update it with "git pull" - else "git clone" it
$(OUTDIR)/cpptext update:
	-@mkdir -p $(OUTDIR)
	-@if [ -d "$(OUTDIR)/cpptext" ]; then 			\
		echo "Updating git repo $(OUTDIR)/cpptext";	\
		cd $(OUTDIR)/cpptext; git pull; 		\
	else							\
		echo "Cloning git repo $(OUTDIR)/cpptext";	\
		cd $(OUTDIR); git clone git@github.com:maartenwrs/cpptext; \
	fi
	make

.PHONY: update
