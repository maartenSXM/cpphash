# check that an esphome virtual environment is setup
ifeq ($(VIRTUAL_ENV),)
  $(warning Did you forgot to source esphome.git/venv/bin/activate?)
endif

# Y1 is run through cpphash and then esphome config > OUT1
# Y2 is only run through esphome config > OUT2

Y1DIR:= ../lily
Y1   := $(Y1DIR)/build/espmake.yaml
Y2   := lilygo-tdisplays3-esphome.yaml

OUT1 := /tmp/cpphash.$(shell echo $$PPID)
OUT2 := /tmp/esphome.$(shell echo $$PPID)


# sort the map keys in the same order
MERGE := ../../yamlmerge.sh -s -e -E

test all:
	@cd $(Y1DIR) && make clean
	@cd $(Y1DIR) && make build/secrets.yaml 
	cd $(Y1DIR)  && make ESP_NOCOMPILE=1 build/espmake.yaml
	cd $(Y1DIR)  && $(MERGE) < build/espmake.yaml > build/esphome.yaml
	cd $(Y1DIR)/build && esphome config esphome.yaml >$(OUT1)
	$(MERGE) < $(Y2) > $(Y2).merged 
	esphome config $(Y2).merged >$(OUT2)
	@if xargs -t -a /dev/null diff $(OUT1) $(OUT2); then    \
	    printf " OK\n*** test passed ***\n"; 		\
	    rm -rf $(OUT1) $(OUT2) $(Y2).merged;	        \
    	else 							\
	    printf " FAIL\n*** Uh oh. Test failed.\n";		\
	    printf "*** This should result in no output:\n";	\
	    printf "\tdiff $(OUT1) $(OUT2)\n";		        \
	    exit 1; 						\
    	fi
