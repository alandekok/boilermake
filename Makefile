# This is a sample "top-level" Makefile.
#
# It can be generated via a "configure" script.  Its purpose is to allow
# projects to have their "own" Makefile, and to put the boilermake rules
# into a "boiler.mk" file that they do not edit.
#

# set a few global definitions.  These will help control "boilermake"

# The absolute path of the top-level source directory.
top_srcdir	= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# The default targets are "all" and "clean", and "install".
# Additional targets are not yet supported.  e.g. if you want to make
# target "foo", then do "cd foo;make".  If "foo" isn't a subdirectory,
# then just "make all".
#
# The whole point of a non-recursive Make system is that it will figure
# out what to do for you.  This means that you do NOT need to specify
# which targets to build

# Cross-platform compilation can be done by defining a path to libtool.
# If LIBTOOL is defined, then any target ending in ".a", ".so", or ".dll"
# is automatically re-written to be a target of ".la".  Libtool is then
# used to compile && link the resulting libraries and programs.
#
##
#LIBTOOL := ${top_srcdir}/jlibtool

# A cross-platform "install" program that works.  You can change this.
INSTALL := ${top_srcdir}/install-sh

# A destination directory for the installation.  Rather than installing
# in /, the files will be installed in this directory.
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
