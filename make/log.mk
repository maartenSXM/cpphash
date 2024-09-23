# This makefile fragment restarts 'make all' to log console output to a file.

# Logging can be skipped using LOG_SKIP=1 on the make command line.

# LOG_SKIP_STDERR=1 on the make command line will only log stdout, not stderr.
# That is useful for paging through stderr using, for example:
#    make LOG_SKIP_STDERR=1 2>&1 >/dev/null | more

ifeq (all,$(LOG_SKIP)$(MAKECMDGOALS))

  MAKECMDGOALS:=log
  $(shell mkdir -p $(CH_BUILD_DIR))
  LOG_FILE := $(CH_BUILD_DIR)/makeall.log

  ifeq (,$(LOG_SKIP_STDERR))
    LOG_STDERR:=2>&1
  endif

log:
	@$(MAKE) -k LOG_SKIP=1 all $(LOG_STDERR) | tee $(LOG_FILE)
	@printf "Makefile: \"make all\" was logged is $(LOG_FILE)\n"

endif
