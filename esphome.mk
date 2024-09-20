# This makefile will skip espmake.yaml compilation when espmake.yaml 
# is unchanged from a previous build.

# The including Makefile should include cpptext.mk, which in turn
# includes this file automatically, when make runs in an esphome venv.

# The including Makefile can define ESP_INIT to an output of
# cpptext.mk (i.e. it is one of the generated files listed
# in CPT_GEN). The default for ESP_INIT is "esphome.yaml".

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

ESP_INIT  ?= esphome.yaml
ESP_YAML  ?= espmake.yaml
ESP_GEN   := $(CPT_BUILD_DIR)/$(ESP_INIT)
ESP_MAIN  := $(CPT_BUILD_DIR)/$(ESP_YAML)
ESP_MERGE := $(CPT_HOME)/yamlmerge.sh -s -e -E

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

esphomeTgt: cppTgt $(ESP_MAIN)
	@printf "esphome.mk: project $(CPT_BUILD_DIR) is up to date.\n"

# File contents (not timestamps) are used as dependencies in this rule.

$(ESP_MAIN): $(call md5,$(ESP_GEN) $(ESP_DEPS))
	@printf "esphome.mk: $(<F:.md5=) changed.\n"
	$(ESP_MERGE) -o "$@" "$(<:.md5=)"
	$(ESP_BUILD_MORE)
ifeq ($(ESP_NOCOMPILE),1)
	cd "$(@D)" && esphome config "$(@F)"
else
	cd "$(@D)" && esphome compile "$(@F)"
endif
	
# Since ESP_MD5FILES can be a long list, avoid blowing ARG_MAX by
# stashing the filenames in a temporary file and passing it to xargs.

define CPT_CLEAN_MORE
	$(eval ESP_CLEAN := $(shell mktemp))
	$(foreach f,				    \
	    $(ESP_MAIN) $(sort $(ESP_MD5FILES)),    \
	    $(file >>$(ESP_CLEAN),$(f)))
	@xargs -t -a $(ESP_CLEAN) rm -f
	@rm -f $(ESP_CLEAN)
	@if [ -f $(CPT_BUILD_DIR)/secrets.yaml ]; then			\
	    xargs -a /dev/null -t rm -f $(CPT_BUILD_DIR)/secrets.yaml;	\
	fi
endef

CPT_REALCLEAN_MORE := rm -rf $(CPT_BUILD_DIR)/.esphome $(CPT_BUILD_DIR)/*.log
