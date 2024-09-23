# Record each distinct PRJ in .cpphash_prj_all

# This makefile fragment requires:
#  PRJ optionally set to a project path
#  PRJ_DEFAULT set to a default project path

define _saveprj
  $(shell grep -sqxF $1 .cpphash_prj_all || echo $1 >> .cpphash_prj_all)
endef

# Check if PRJ= was specified on the command line to select a project.
# Make doesn't have compound conditionals so just use branchy logic
  # If it was specified but doesn't exist, complain.
  # If it wasn't specified, try lookup the last known project.
  # If it still exists, use it.
  # If it doesn't exist, use the specified default project if it exists
  # If the default project was specified but doesn't, complain.
  # If the default project wasn't specified, use the word "default"

ifneq (,$(PRJ))
  # PRJ is specified. Require that it exists.
  ifeq (,$(wildcard $(PRJ)))
    $(error $(MAKEFILE): $(PRJ) not found)
  endif
else
  # no PRJ is specified

  # if the is a project record, check the last known project
  ifneq (,$(wildcard .cpphash_prj))
    PRJ := $(shell cat .cpphash_prj)
    # if last known project is missing, use the default project
    ifeq (,$(wildcard $(PRJ)))
      ifneq (,$(wildcard $(PRJ_DEFAULT)))
        PRJ := $(PRJ_DEFAULT)
      else
        PRJ := default
      endif
    endif
  else
    ifneq (,$(wildcard $(PRJ_DEFAULT)))
      ifeq (,$(wildcard $(PRJ_DEFAULT)))
        $(error $(MAKEFILE): PRJ_DEFAULT not found)
      endif
      PRJ := $(PRJ_DEFAULT)
    else
      PRJ := default
    endif
  endif
endif

# update the project records
$(shell echo $(PRJ) > .cpphash_prj)
$(call _saveprj,$(PRJ))

