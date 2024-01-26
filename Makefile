ifneq (,$(wildcard ./dehash.sh))
OUTDIR=..
else
OUTDIR=.
-include $(OUTDIR)/cpptext/Makefile.cpptext
endif

.PHONY: update
# if cpptext non-existent, clone it. Otherwise, only if explicit update
$(OUTDIR)/cpptext update:
	-@mkdir $(OUTDIR)
	-@if [ -d "$(OUTDIR)/cpptext" ]; then 			\
		echo "Updating git repo $(OUTDIR)/cpptext";	\
		cd $(OUTDIR)/cpptext; git pull; 		\
	else							\
		echo "Cloning git repo $(OUTDIR)/cpptext";	\
		cd $(OUTDIR); git clone git@github.com:maartenwrs/cpptext \
	fi
	make

