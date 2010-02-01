# subdirs normally have a "Makefile" that does nothing more than
#
# 	include ../../../../Makefile
#
# If you don't want to create all of those "../" by hand, then copy
# this file to every subdirectory, as "Makefile".  It will automatically
# figure out where in the directory tree it is located, and call the
# top-level Makefile.
#

# The name of the top-level Makefile.  Note that using this file
# instead of the "include ../../../Makefile" method means that you
# MUST define a top-level Makefile in each subdirectory.  This can be
# more work than creating an "include" line once.  So use the
# "include" method instead.
#
MAIN_MK := main.mk

#  If we notice that the current directory doesn't have a "main.mk"
# file, we walk back up the directory tree until we find one.
#
sp :=
sp +=
walk = $(if $1,$(wildcard /$(subst $(sp),/,$1)/$2) $(call walk,$(wordlist 2,$(words $1),x $1),$2))
find = $(firstword $(call walk,$(strip $(subst /, ,$1)),$2))
root := $(patsubst %/${MAIN_MK},%,$(call find,$(CURDIR),${MAIN_MK}))

ifeq (${root},)
$(error Failed to find a top-level "${MAIN_MK}" file)
endif

subdir :=$(subst ${root}/,,${PWD})

# We're in a subdirectory, go back up to the root, and re-build
# everything from there.
#
# Add any global targets like "install" here.  Just make sure that
# "all" is the first target on the line, so that it is the default
# target.
#
all clean:
	@$(MAKE) -C ${root} SUBDIR=${subdir} $@
