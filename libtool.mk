# Copyright 2008, 2009, 2010 Dan Moulding, Alan T. DeKok
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Add these rules only when LIBTOOL is being used.
ifneq "${LIBTOOL}" ""

# JLIBTOOL - check if we're using the local (fast) jlibtool, rather
#   than the GNU (slow) libtool shell script.  If so, add rules
#   to build it.

ifeq "${LIBTOOL}" "JLIBTOOL"
    JLIBTOOL := $(abspath ${BUILD_DIR}/make/jlibtool)

    # Add a rule to build jlibtool BEFORE any other targets.  This
    # means that we can use it to build the later targets.
    all install: ${JLIBTOOL}

    # Note that we need to use a compilation rule that does NOT
    # include referencing ${LIBTOOL}, as we don't have a jlibtool
    # binary!
    jlibtool ${JLIBTOOL}: ${top_makedir}/jlibtool.c
	${CC} $< -o ${JLIBTOOL}

    clean: jlibtool_clean

    .PHONY: jlibtool_clean
    jlibtool_clean:
	rm -f ${JLIBTOOL}

    # Tell GNU Make to use this value, rather than anything specified
    # on the command line.
    override LIBTOOL := ${JLIBTOOL}
endif    # else we're not using jlibtool

# When using libtool, it produces a '.libs' directory.  Ensure that it
# is removed on "make clean", too.
#
clean: .libs_clean

.PHONY: .libs_clean
.libs_clean:
	rm -rf ${BUILD_DIR}/.libs/

# Re-define compilers and linkers
#
OBJ_EXT := lo
COMPILE.c := ${LIBTOOL} --mode=compile ${CC}
COMPILE.cxx := ${LIBTOOL} --mode=compile ${CXX}
LINK.c := ${LIBTOOL} --mode=link ${CC}
LINK.cxx := ${LIBTOOL} --mode=link ${CXX}
PROGRAM_INSTALL := ${LIBTOOL} --mode=install ${INSTALL}


# INSTALL_NAME - Function to return the name of the file which should
#   be installed.  For libtool builds, the "normal" target has had
#   RPATH set up to allow binaries to be run out of the TARGET_DIR.
#   We can't install these binaries, as they refer to the source tree.
#   Therefore, we make the installation depend on a separate target,
#   which has the correct installation RPATH, and is located in the
#   BUILD_DIR.
define INSTALL_NAME
${${1}_RELINK}
endef

# LIBTOOL_ENDINGS - Given a library ending in ".a" or ".so", replace that
#   extension with ".la".
#
define LIBTOOL_ENDINGS
$(patsubst %.a,%.la,$(patsubst %.so,%.la,${1}))
endef

# ADD_TARGET_RULE.la - Build a ".la" target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.la
    # Create libtool library ${1}
    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @$(strip mkdir -p $(dir ${1}))
	    $${${1}_LINKER} -o $$@ $${RPATH_FLAGS} $${LDFLAGS} \
                $${${1}_LDFLAGS} $${${1}_OBJS} $${LDLIBS} $${${1}_LDLIBS}
	    $${${1}_POSTMAKE}

endef

# If we're using LIBTOOL *and* an installation directory is defined,
# then libtool can build dynamic libraries.  Otherwise, build static
# libraries.
ifneq "${libdir}" ""
    # RPATH  : flags use to build executables that can be run
    #          from the build directory / source tree.
    # RELINK : flags use to build executables that are installed,
    #          with no dependency on the source. 
    RPATH_FLAGS := -rpath $(abspath ${BUILD_DIR})/lib/.libs -rdynamic
    RELINK_FLAGS := -rpath ${libdir} -rdynamic
else
    RPATH_FLAGS := -static
endif

# UPDATE_TARGET_ENDINGS - Function to turn target into a libtool target
#   e.g. "libfoo.a" -> libfoo.la"
#
#   If the target is an executable, then its extension doesn't change
#   when we use libtool, and we don't do any re-writing.
#
#   USE WITH EVAL
#
define ADD_LIBTOOL_SUFFIX
    ifneq "$$(call LIBTOOL_ENDINGS,$${TGT})" "$${TGT}"
        TGT_NOLIBTOOL := $${TGT}
        TGT := $$(call LIBTOOL_ENDINGS,$${TGT})
        $${TGT}_NOLIBTOOL := $${TGT_NOLIBTOOL}
    endif

    # re-write all of the dependencies to have the libtool endings.
    TGT_PREREQS := $$(call LIBTOOL_ENDINGS,$${TGT_PREREQS})
endef

# ADD_LIBTOOL_TARGET - Function to ensure that the object files depend
#   on our jlibtool target.  This ensures that jlibtool is built before
#   it's used to build the object files.
#
#   USE WITH EVAL
#
define ADD_LIBTOOL_TARGET
    ifeq "${LIBTOOL}" "JLIBTOOL"
        $${$${TGT}_OBJS}: $${JLIBTOOL}
    endif
endef


endif
