# check that an esphome virtual environment is setup
ifeq ($(VIRTUAL_ENV),)
  $(warning Did you forgot to source esphome.git/venv/bin/activate?)
endif

Y1DIR     := ../../examples/esphome
YAML1     := espmake.yaml
YAML2     := lilygo-tdisplays3-esphome.yaml
ESPMAKE   := ./tmp.$(shell echo $$PPID)
ESPHOME   := ./tmp.$(shell echo $$PPID)
YAMLMERGE := ../../yamlmerge.sh -s -e

test all:
	@printf "Creating $(ESPMAKE) using cpphash from $(Y1DIR)/$(YAML1) ..."
	@make -C $(Y1DIR) clean > /dev/null; 
	@make -C $(Y1DIR) all >/dev/null 2> /dev/null;
	@cd $(Y1DIR)/build/lily && \
		esphome config $(YAML1) >$(ESPMAKE) 2> /dev/null
	@printf "done.\n"
	@printf "Creating $(ESPHOME) using esphome from $(YAML2) ..."
	@esphome config $(YAML2) >$(ESPHOME) 2> /dev/null
	@printf "done.\n"
	$(YAMLMERGE) -o $(ESPHOME).yq $(ESPHOME)
	@mv $(ESPHOME).yq $(ESPHOME)
	@printf "Comparing espmake and esphome configs..."
	@if diff $(ESPMAKE) $(ESPHOME); then			\
	    printf " OK\n*** test passed ***\n"; 		\
	    rm -rf $(ESPMAKE) $(ESPHOME);			\
    	else 							\
	    printf "*** Uh oh. Test failed. Check with:\n";	\
	    printf "diff $(ESPMAKE) $(ESPHOME)\n";		\
	    exit 1; 						\
    	fi

.PHONY: test
