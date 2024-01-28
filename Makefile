# Copy this Makefile to any directory that you want to use cpptext
# with. This Makefile will install cpptext under that directory
# and you can then use make to build your text files with c preprocessor
# directive features.
#
# "make" will install cpptext under OUTDIR once. Aftewards, it will
# revert to "make all" of cpptext/Makefile.cpptext.
#
# "make update" will update cpptext form github.
#
# Refer to github.com/maartenwrs/cpptext for more details on cpptext.
#
OUTDIR := .

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

.PHONY: update
