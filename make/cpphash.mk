# cpphash.mk is from https://github.com/maartenSXM/cpphash.
#
# This file is intended to be included from your project Makefile and
# depends on $(CH_HOME) being a git clone of github.com/maartenSXM/cpphash.
#
# See https://github.com/maartenSXM/cpphash/blob/main/Makefile for
# an example of how to automatically setup this repo as a submodule
# and include this file from a Makefile.
#
# Refer to https://github.com/maartenSXM/cpphash/blob/main/README.md
# for more details.

MAKEFLAGS    += --no-builtin-rules
MAKEFLAGS    += --no-builtin-variables
MAKECMDGOALS ?= all

# These can be optionally overridden in a project Makefile that
# includes this cpphash.mk file. 

# set some defaults for unset simply expanded variables

ifeq (,$(CH_HOME))
CH_HOME := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
endif
ifeq (,$(CH_BUILD_DIR))
CH_BUILD_DIR := build
endif
ifeq (,$(CH_TMP_SUBDIR))
CH_TMP_SUBDIR := dehashed
endif

# Use these overrides to specify dependencies that customize the build
CH_PRE_TGT  ?= 
CH_MAIN_TGT ?= cppTgt
CH_POST_TGT ?= 

# automatically
ifeq (,$(findstring esphome,$(VIRTUAL_ENV)))
endif

# Use these to specify dependicies that customize cleaning.  This inializes them.
CH_EXTRA_CLEAN_TGT    := $(if $(CH_EXTRA_CLEAN_TGT),$(CH_EXTRA_CLEAN_TGT),)
CH_EXTRA_REALCLEAN_TGT:= $(if $(CH_EXTRA_REALCLEAN_TGT),$(CH_EXTRA_REALCLEAN_TGT),)

ifeq ($(CH_SRCS),)
  $(error "set CH_SRCS to the files you want to run dehash.sh on")
endif

ifeq ($(CH_GEN),)
  $(error "set CH_GEN to the files you want to run cpp on")
endif

ifeq ($(shell which gcc),)
  $(error "gcc not found. Please install it")
endif

ifeq (,$(findstring GNU,$(shell sed --version 2>/dev/null)))
  ifeq (,$(shell which gsed))
    $(error "GNU sed not found. Please install it")
  else
    SED=gsed
  endif
else
    SED=sed
endif

ifeq ($(CH_BUILD_DIR),.)
  $(error "CH_BUILD_DIR set to . is not supported.")
endif

CH_TMP_DIR  := $(CH_BUILD_DIR)/$(CH_TMP_SUBDIR)
CH_DEHASH   := $(CH_HOME)/dehash.sh --cpp
CH_INFILES  := $(sort $(patsubst ./%,%,$(CH_SRCS)))
CH_OUTFILES := $(addprefix $(CH_BUILD_DIR)/,$(patsubst ./%,%,$(CH_GEN)))

CH_CPPFLAGS := -x c -E -P -undef -Wundef -Werror -nostdinc \
		 $(CH_EXTRA_FLAGS)

# setup #includes so that all dehashed source directories come first,
# followed by all source directories. Thus, includes of yaml files will
# include the dehashes variants of the file and includes of non-yaml
# files such as images will come from the source tree.

CH_CPPINCS   := -I $(CH_TMP_DIR)					\
	         $(foreach d,$(patsubst %/,%,				\
		   $(sort $(dir $(CH_SRCS)))),-I $(CH_TMP_DIR)/$(d))	\
	         $(foreach d,$(patsubst %/,%,				\
		   $(sort $(dir $(CH_SRCS)))),-I $(d))			\
		 $(CH_EXTRA_INCS)

CH_CPPDEFS   := -D CH_USER_$(USER)=1 -D CH_USER=$(USER)   \
	       $(CH_EXTRA_DEFS)

CH_CPP	= gcc $(CH_CPPFLAGS) $(CH_CPPINCS) $(CH_CPPDEFS) 

# CH_TMP_SRCS is the list of dehashed files in CH_TMP_DIR
CH_TMP_SRCS = $(addprefix $(CH_TMP_DIR)/, \
		 $(sort $(patsubst ./%,%,$(CH_INFILES))))

# create all build directories (sort filters duplicates)
CH_MKDIRS := $(sort $(CH_BUILD_DIR)		\
		     $(CH_TMP_DIR)		\
		     $(dir $(CH_TMP_SRCS))	\
		     $(dir $(CH_OUTFILES)))

$(shell mkdir -p $(CH_MKDIRS))

# skip include of esphome.mk by defining CH_NO_ESPHOME to non-empty
ifeq (,$(CH_NO_ESPHOME))
  # include esphome.mk if ESP_INIT is defined
  ifneq (,$(ESP_INIT))
    CH_MAIN_TGT = esphomeTgt
    include $(CH_HOME)/make/esphome.mk
  endif
endif

all: $(CH_PRE_TGT) $(CH_MAIN_TGT) $(CH_POST_TGT) 

define _uptodate
  printf "cpphash.mk: $(1) is up to date.\n";
endef

cppTgt: $(CH_INFILES) $(CH_OUTFILES)
	@$(foreach tgt,$(notdir $(CH_OUTFILES)),$(call _uptodate,$(tgt)))

$(CH_INFILES):
	$(error source file $@ does not exist)

# Emit the rules that run cpp to generate all the CH_OUTFILES

define _cpp
$(CH_BUILD_DIR)/$(1): $(CH_TMP_DIR)/$(1) $(CH_TMP_SRCS)
	$(CH_CPP) -MD -MP -MT $$@ -MF $$<.d $$< -o $$@
	$(CH_CPP_MORE)
endef
$(foreach src,$(patsubst ./%,%,$(CH_GEN)),$(eval $(call _cpp,$(src))))

# Emit the rules that dehash the sources into the project directory

define _dehash
$(CH_TMP_DIR)/$(1): $(1)
	@printf "Dehashing to $$@\n"
	@$(CH_DEHASH) $$< >$$@
endef

$(foreach src,$(patsubst ./%,%,$(CH_INFILES)), $(eval $(call _dehash,$(src))))

# Include the dependency rules generated from a previous build, if any

-include $(wildcard $(CH_TMP_DIR)/*.d)

clean: $(CH_EXTRA_CLEAN_TGT)
	rm -rf $(CH_TMP_DIR) $(CH_OUTFILES) $(CH_CLEAN_FILES)
	$(CH_CLEAN_MORE)

realclean: clean $(CH_EXTRA_REALCLEAN_TGT)
	-@if [ "`git -C $(CH_HOME) status --porcelain`" != "" ]; then	\
		printf "$(CH_HOME) not porcelain. Leaving it.\n";	\
	else								\
		echo rm -rf $(CH_HOME);				\
		rm -rf $(CH_HOME);					\
	fi
	rm -rf $(CH_TMP_DIR) $(CH_REALCLEAN_FILES)
	$(CH_REALCLEAN_MORE)

define _print_defaults
print-defaults:: cppTgt $(CH_TMP_DIR)/$(1)
	@printf "Default values for $(1)\n"
	@$(CH_CPP) -CC $(CH_TMP_DIR)/$(1) | \
		grep '^//#default' | $(SED) 's/^../  /'
endef

$(foreach gen,$(patsubst ./%,%,$(CH_GEN)), \
    $(eval $(call _print_defaults,$(gen))))

.PRECIOUS: $(CH_TMP_DIR) $(CH_BUILD_DIR) $(CH_HOME)
.PHONY: all clean realclean mkdirs cppTgt print-defaults \
		    $(CH_PRE_TGT) $(CH_MAIN_TGT) $(CH_POST_TGT)

