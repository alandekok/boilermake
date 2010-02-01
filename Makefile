# This is a sample "top-level" Makefile.
#
# It can be generated via a "configure" script.  Its purpose is to allow
# projects to have their "own" Makefile, and to put the boilermake rules
# into a "boiler.mk" file that they do not edit.
#

# set a few global definitions.  These will help control "boilermake"

# The absolute path of the top-level source directory.
top_srcdir	= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# The default targets are "all" and "clean".  Define additional targets
# so that the submakefiles can work.  i.e. This lets you do:
#
#	cd subdir
#	make install
#
# and it will "just work".
#
# The actual targets should be set in the "main.mk" file, and not
# here.  Setting them here will cause Make to complain about "old
# commands" for the target.
#
ALL_TARGETS := install

# Cross-platform compilation can be done by defining a path to libtool.
# If LIBTOOL is defined, then any target ending in ".a", ".so", or ".dll"
# is automatically re-written to be a target of ".la".  Libtool is then
# used to compile && link the resulting libraries and programs.
#
##
#LIBTOOL := /path/to/libtool

# A cross-platform "install" program that works.  You can change this.
INSTALL := ${top_srcdir}/install-sh

# A destination directory for the installation.  Rather than installing
# in /, the files will be installed in this directory
##
#DESTDIR := ${HOME}

# Most packages bootstrap off of a "prefix" directory, and set a number
# of paths based from that.  Here are some common ones that you can
# customize for your package.  If you are using a "configure" script,
# these should be auto-generated from the configure output.
#
prefix		= /usr/local
exec_prefix	= ${prefix}
sysconfdir	= ${prefix}/etc
localstatedir	= ${prefix}/var
libdir		= ${exec_prefix}/lib
bindir		= ${exec_prefix}/bin
sbindir		= ${exec_prefix}/sbin
datarootdir	= ${prefix}/share
docdir		= ${datadir}/doc
mandir		= ${datarootdir}/man
datadir		= ${datarootdir}
logdir		= ${localstatedir}/log
includedir	= ${prefix}/include

# Include the boilermake file, which has all of the magic to set up
# the rest of the rules.
#
include $(dir $(lastword $(MAKEFILE_LIST)))/boiler.mk
