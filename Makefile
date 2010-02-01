# This is a sample "top-level" Makefile.
#
# It can be generated via a "configure" script.  Its purpose is to allow
# projects to have their "own" Makefile, and to put the boilermake rules
# into a "boiler.mk" file that they do not edit.
#

# set a few global definitions.  These will help control "boilermake"

# The default targets are "all" and "clean".  Set additional targets here
# so that the submakefiles can work.  i.e. This lets you do
#
#	cd subdir
#	make install
#
# and it will "just work".
#
# These targets should be defined in the "main.mk" file, and not here.
# Defining them here will cause Make to complain about "old commands"
# for the target.
#
ALL_TARGETS := install

# TO DO: set "prefix", INSTALL, libdir, etc.

# Cross-platform compilation can be done by defining a path to libtool.
# If LIBTOOL is defined, then any target ending in ".a", ".so", or ".dll"
# is automatically re-written to be a target of ".la".  Libtool is then
# used to compile && link the resulting libraries and programs.
#
#LIBTOOL := /path/to/libtool

# Include the boilermake file, which has all of the magic to set up
# the rest of the rules.
#
include $(dir $(lastword $(MAKEFILE_LIST)))/boiler.mk
