# This makefile will skip espmake.yaml compilation when espmake.yaml 
# is unchanged from a previous build.

# The including Makefile should include cpphash.mk, which in turn
# includes this file automatically, when make runs in an esphome venv.

# Note: the including Makefile must define ESP_INIT to an output of
# cpphash.mk (i.e. it is one of the generated files listed
# in CH_GEN).

# The including Makefile can also define ESP_YAML to the name of the yaml
# file that this Makefile should generate using yamlmerge.sh, for processing
# by esphome. The default for ESP_YAML is "espmake.yaml".

# In order to avoid unecessary build, this Makefile considers changes to
# the contents of files in addition to timestamps to trigger actions.
# It achieves that by calculating md5 checksums of dependency files.
# The md5 files are only updated when the checksum of the corresponding
# file changes, which allows rules to be written against the md5 files
# instead of the corresponding source files. This allows files to have
# newer or older timestamps than the md5 files as long as the file contents
# are the same as when the md5 file was created.

# "make clean" removes the md5 files to enable a subsequent full esphome
# build. "make realclean" removes the .esphome build directory as well
# as build logs files.

ifeq ($(shell which md5sum),)
  $(error "md5sum not found. Please install it")
endif

ifeq (,$(ESP_INIT))
  $(error esphome.mk: ESP_INIT not defined)
endif

ESP_YAML  ?= espmake.yaml
ESP_GEN   := $(CH_BUILD_DIR)/$(ESP_INIT)
ESP_MAKE  := $(CH_BUILD_DIR)/$(ESP_YAML)
ESP_MERGE := $(CH_HOME)/yamlmerge.sh -e -i -t id

# md5 adds .md5 suffix to file names and records them for "make clean"
md5 = $(addsuffix .md5,$1)$(eval ESP_MD5FILES += $(addsuffix .md5,$1))

# The md5 is calculated and stashed in CHECKSUM. If the existing .md5
# file doesn't exist or it has changed, then the .md5 file is updated.

.SUFFIXES: .md5
%.md5: %
	@$(eval CHECKSUM := $(shell md5sum "$*"))			\
	  $(if $(filter-out $(shell cat "$@" 2>/dev/null),$(CHECKSUM)),	\
	    echo $(CHECKSUM) > "$@")

.PHONY: esphomeTgt

esphomeTgt: cppTgt $(ESP_MAKE)
	@printf "esphome.mk: project $(CH_BUILD_DIR) is up to date.\n"

ifeq ($(ESP_NOCOMPILE),)
  # Force an esphome compile when main.cpp or firmware.bin are not found.
  # Also force an esphome compile when main.cpp is newer than firmware.bin.
  FORCE: ;
  # wildcard-ing avoids having to grok .esphome.name from $(ESP_MAKE)
  ESP_PIOENVS_DIR:=$(wildcard $(CH_BUILD_DIR)/.esphome/build/*/.pioenvs)
  ESP_MAIN_CPP:=$(wildcard $(ESP_PIOENVS_DIR)/../src/main.cpp)
  ESP_FIRMWARE:=$(wildcard $(ESP_PIOENVS_DIR)/*/firmware.bin)
  ifeq (,$(ESP_MAIN_CPP))
     ESP_COMPILE_FORCE=FORCE
  endif
  ifeq (,$(ESP_FIRMWARE))
     ESP_COMPILE_FORCE=FORCE
  endif
  ifneq (,$(ESP_MAIN_CPP))
    ifneq (,$(ESP_FIRMWARE))
      ifeq (y,$(shell test $(ESP_MAIN_CPP) -nt $(ESP_FIRMWARE) && echo y))
        ESP_COMPILE_FORCE=FORCE
      endif
    endif
  endif
endif

# File contents (not timestamps) are used as dependencies in this rule.

$(ESP_MAKE): $(call md5,$(ESP_GEN) $(ESP_DEPS)) $(ESP_COMPILE_FORCE)
	@printf "esphome.mk: $(<F:.md5=) changed.\n"
	$(ESP_MERGE) -o "$@" "$(<:.md5=)"
	$(ESP_BUILD_MORE)
ifeq ($(ESP_NOCOMPILE),1)
	cd "$(@D)" && esphome config "$(@F)"
else
	cd "$(@D)" && esphome compile "$(@F)"
endif
	
define CH_CLEAN_MORE
	rm -f $(ESP_MAKE) $(ESP_MD5FILES)
	@if [ -f $(CH_BUILD_DIR)/secrets.yaml ]; then	\
	    echo rm -f $(CH_BUILD_DIR)/secrets.yaml;	\
	    rm -f $(CH_BUILD_DIR)/secrets.yaml;	\
	fi
endef

CH_REALCLEAN_MORE := rm -rf $(CH_BUILD_DIR)/.esphome $(CH_BUILD_DIR)/*.log

