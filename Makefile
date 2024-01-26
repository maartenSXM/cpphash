# Copy just this Makefile to any directory that you want to use cpptext
# with.  It will clone cpptext under that directory and you can then 
# use make to build your text files with c preprocessor directive features.
#
ifneq (,$(wildcard ./dehash.sh))
OUTDIR=..
update:
else
OUTDIR=.
-include $(OUTDIR)/cpptext/Makefile.cpptext
$(OUTDIR)/cpptext update:
endif
	-@mkdir -p $(OUTDIR)
	# if cpptext exists, "git pull" it else clone it
	-@if [ -d "$(OUTDIR)/cpptext" ]; then 			\
		echo "Updating git repo $(OUTDIR)/cpptext";	\
		cd $(OUTDIR)/cpptext; git pull; 		\
	else							\
		echo "Cloning git repo $(OUTDIR)/cpptext";	\
		cd $(OUTDIR); git clone git@github.com:maartenwrs/cpptext; \
	fi
ifeq (,$(wildcard ./dehash.sh))
	make
endif

.PHONY: update
