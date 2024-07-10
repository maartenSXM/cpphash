# "./makefile" and this file, "./Makefile", are based on examples from:
#
#       github.com/maartenSXM/cpptext
#
# "./makefile" automatically installs cpptext and then includes this file.
#
# Note: OUTDIR  is specified in "./makefile" and the default is "."

MAIN	:= main.yaml
SUFFIX	:= $(suffix $(MAIN))
DIRS	:= .
SRCS	:= $(foreach d,$(DIRS),$(wildcard $(d)/*$(SUFFIX)))
PREFIX	:= myProj_
PROJTAG	:= 0

include $(OUTDIR)/cpptext/Makefile.cpptext

# uncomment the next line for esphome projects
# include $(OUTDIR)/cpptext/Makefile.esphome

