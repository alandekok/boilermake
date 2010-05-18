# boilermake: A reusable, but flexible, boilerplate Makefile.
#
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

# ADD_LEGACY_RULE - Parametric "function" that creates legacy Makefiles
#   in the ${BUILD_DIR}/make/ directory.
#
define ADD_LEGACY_RULE
    # The makefile is named for the source file, in the "make" directory,
    # with a ".mk" extension.
    ${1}_LEGACY := $$(patsubst $${BUILD_DIR}/%,$${BUILD_DIR}/make/%,$${${1}_BUILD})/${1}.mk

    ALL_LEGACYMK += $${${1}_LEGACY}

    # gnu.mak needs to have a line saying "include foo.mk"
    $${BUILD_DIR}/make/gnu.mk: $${${1}_LEGACY}

    # The legacy makefile depends on the build Makefiles.  If they change,
    # we presume that the definitions or list of sources has changed,
    # and we need to re-build the legacy Makefile.
    #
    # We also remove leading spaces, and convert raw "build" to "${BUILD}"
    $${${1}_LEGACY}: $${${1}_MAKEFILES}
	@mkdir -p $$(dir $$@)
	@${MAKE} -s LEGACY=yes ${1} | sed \
		-e 's/^ *//' \
		-e 's, $${BUILD_DIR}, $$$${BUILD_DIR},g' > $$@

    # If we're building this legacy Makefile, then print the rules to
    # STDOUT.  The above wrapper will take care of setting "LEGACY=yes"
    ifeq "${LEGACY}" "yes"
        ifeq "$${MAKECMDGOALS}" "${1}"

            $$(info # Variable definitions)
            $$(foreach x, CFLAGS CXXFLAGS SOURCES DEPS DEFS INCDIRS OBJS \
                          LDFLAGS LDLIBS POSTMAKE LINKER POSTCLEAN INSTALLDIR \
                          POSTINSTALL PREREQS RPATHREQS RPATHLIBS MAN \
                          RELINK PRLIBS PRBIN BUILD,\
                $$(info ${1}_$${x} := $${${1}_$${x}}))

            $$(info )
            $$(info $$(call ADD_TARGET_TO_ALL,${1}))
            $$(info $$(call ADD_TARGET_RULE$${${1}_SUFFIX},${1}))
            $$(info )
            $$(info $$(call ADD_CLEAN_RULE,${1}))

            $$(info )
            $$(info # Include Makefiles which contain the generated dependencies.)
            $$(info # The empty target is to tell Make that it's OK if they don't exist)
            $$(info $$$${${1}_DEPS}:)
            $$(info )
            $$(info -include $$$${${1}_DEPS})

            $$(info )
            $$(info # Rules for C files)
            $$(foreach x, $$(filter $${C_SRC_EXTS},$${${1}_SOURCES}),\
                $$(info $$(call ADD_COMPILE_RULE.c,$${x},${1})))

            $$(info )
            $$(info # Rules for C++ files)
            $$(foreach x, $$(filter $${CXX_SRC_EXTS},$${${1}_SOURCES}),\
                $$(info $$(call ADD_COMPILE_RULE.cxx,$${x},${1})))

        endif
    endif

endef

ALL_LEGACYMK :=

# LEGACY_FILTER_DEPENDS - Parameterized "function" that filters the
#  dependencies.  It is a copy of FILTER_DEPENDS, with $$* changed to
#  $(basename ${1}) for portability.  The BSD Make treats $* as the
#  base filename without suffix *or* directory path.  e.g. bar/foo.c -> foo
#
define LEGACY_FILTER_DEPENDS
	@mkdir -p $(dir $${BUILD_DIR}/make/src/${1})
	@sed  -e 's/#.*//' \
	  -e 's, /[^: ]*,,g' \
	  -e 's,^ *[^:]* *: *$$$$,,' \
	  -e '/: </ d' \
	  -e '/^ *\\$$$$/ d' \
	  -e 's,^$${BUILD_DIR},$$$${BUILD_DIR},' \
	  -e '/^$$$$/ d' \
	  < $${BUILD_DIR}/objs/$(basename ${1}).d | sed -e '$$$$!N; /^\(.*\)\n\1$$$$/!P; D' \
	  >  $${BUILD_DIR}/make/src/$(basename ${1}).mk
	@sed -e 's/#.*//' \
	  -e 's, /[^: ]*,,g' \
	  -e 's,^ *[^:]* *: *$$$$,,' \
	  -e '/: </ d' \
	  -e 's/^[^:]*: *//' \
	  -e 's/ *\\$$$$//' \
	  -e '/^$$$$/ d' \
	  -e 's/$$$$/ :/' \
	  < $${BUILD_DIR}/objs/$(basename ${1}).d | sed -e '$$$$!N; /^\(.*\)\n\1$$$$/!P; D' \
	 >> $${BUILD_DIR}/make/src/$(basename ${1}).mk
	 rm -f $${BUILD_DIR}/objs/$(basename ${1}).d
endef

# ADD_COMPILE_RULE.c - Parameterized "function" that adds a new rule
#   which says how to compile a .c file into a .o file.  This is a copy
#   of COMPILE_C_CMDS, with edits.  The GNU Make per-target variables
#   have been changed to target-specific global variables.
#   USE WITH EVAL
#
define ADD_COMPILE_RULE.c
    $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}: ${1}
	@$(strip mkdir -p $(dir $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}))
	$${COMPILE.c} -o $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT} -c $${CFLAGS} $${${2}_CFLAGS} \
            $${${2}_INCDIRS} $${${2}_DEFS} ${1}

endef

# ADD_COMPILE_RULE.cxx - Parameterized "function" that adds a new rule
#   which says how to compile a .cc file into a .o file.  This is a copy
#   of COMPILE_CXX_CMDS, with edits.  The GNU Make per-target variables
#   have been changed to target-specific global variables.

#   USE WITH EVAL
#
define ADD_COMPILE_RULE.cxx
    $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}: ${1}
	@$(strip mkdir -p $(dir $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}))
	$${COMPILE.cxx} -o $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT} -c $${CXXFLAGS} $${${2}_CXXFLAGS} \
            $${${2}_INCDIRS} $${${2}_DEFS} ${1}
	[ "$${CPP_MAKEDEPEND}" != "yes" ] || $${CPP} $${CPPFLAGS} $${${1}_INCDIRS} $${${1}_DEFS} $$< | sed \
	  -n 's,^\# *[0-9][0-9]* *"\([^"]*\)".*,$$@: \1,p' > $${BUILD_DIR}/objs/$(basename ${1}).d
$(call LEGACY_FILTER_DEPENDS,${1})

endef

# Create a file containing the variable definitions
.PHONY: ${BUILD_DIR}/make/defs.mk
${BUILD_DIR}/make/defs.mk:
	@mkdir -p $(dir $$@)
	@${MAKE} -s LEGACY=yes defs.mk | sed 's/^ *//' > $@

# If we're building a Makefile, have an empty target so that Make doesn't
# complain, and then do the real work in a macro.
ifneq "${LEGACY}" ""
.PHONY: defs.mk
defs.mk:

    ifeq "${LEGACY}" "yes"
        ifeq "${MAKECMDGOALS}" "defs.mk"
            $(info # Variable definitions)
            $(foreach x, CFLAGS CXXFLAGS DEFS INCDIRS LDFLAGS LDLIBS  \
                          MAN BUILD_DIR TARGET_DIR OBJ_EXT \
                          COMPILE.c COMPILE.cxx CPP LIBTOOL \
                          prefix exec_prefix bindir sbindir libdir sysconfdir \
                          localstatedir datadir mandir docdir logdir \
                          includedir,\
                $(info ${x} := ${${x}}))
        endif
    endif
endif

# The GNU compatible makefile depends on the Makefiles for all of
# defined targets.
${BUILD_DIR}/make/gnu.mk: ${BUILD_DIR}/make/defs.mk
	@echo "include $<" > $@
	@echo ".PHONY: all clean" >> $@
	@echo "all clean:" >> $@
	@echo "" >> $@
	@for x in ${ALL_LEGACYMK}; do \
		echo "include $$x" >> $@; \
	done
