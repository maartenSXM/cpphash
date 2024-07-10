# check that an esphome virtual environment is setup
ifeq ($(VIRTUAL_ENV),)
  $(warning Did you forgot to source esphome.git/venv/bin/activate?)
endif

# Y1 is run through cpptext and then esphome config > OUT1
# Y2 is only run through esphome config > OUT2

Y1   := ../make/myProj_0.yaml
Y2   := lilygo-tdisplays3-esphome.yaml

OUT1 := /tmp/cpptext.$(shell echo $$PPID)
OUT2 := /tmp/esphome.$(shell echo $$PPID)

test all:
	@printf "Creating $(OUT1) from $(Y1) ..."
	@make -C $(dir $(Y1)) clean > /dev/null
	@make -C $(dir $(Y1)) all   > /dev/null 2> /dev/null
	@cd $(dir $(Y1)); esphome config $(notdir $(Y1)) >$(OUT1) 2> /dev/null
	@printf "done.\n"
	@printf "Creating $(OUT2) from $(Y2) ..."
	@esphome config $(Y2) >$(OUT2) 2> /dev/null
	@printf "done.\n"
	@printf "Comparing generated $(Y1) config with $(Y2) config ..."
	@if diff $(OUT1) $(OUT2); then			        \
	    printf " OK\n*** test passed ***\n"; 		\
	    rm -rf $(OUT1) $(OUT2);			        \
    	else 							\
	    printf "*** Uh oh. Test failed.			\
	    printf "*** This should result in no output:	\
	    printf "\tdiff $(OUT1) $(OUT2)\n";		        \
	    printf "*** And this be only blank lines and comments:";	\
	    printf "\tdiff $(dir $(Y1))/myProj_0.yaml $(Y2)\n";	\
	    exit 1; 						\
    	fi
