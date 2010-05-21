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

# ADD_LEGACY_VARIABLES - Parametric "function" that defines target
#   and directory specific variables.  GNU Make supports per-object
#   variables.  Other Make implementations do not.  So we cater to
#   them for legacy Makefiles.
#
#  USE WITH EVAL
#
define ADD_LEGACY_VARIABLES
    # These macros are specific to each target *and* the subdirectory.
    # These rules are for the legacy.mk generation.
    ${2}_MAKEDIRS := $$(sort $${${2}_MAKEDIRS} ${1})
    ifeq "$$(words $${${2}_MAKEDIRS})" "1"
        ${2}_CFLAGS := $${SRC_CFLAGS}
        ${2}_CXXFLAGS := $${SRC_CXXFLAGS}
        ${2}_DEFS := $$(addprefix -D,$${SRC_DEFS})
        ${2}_INCDIRS := $$(addprefix -I,$${SRC_INCDIRS})
    else
        ${2}_${1}_used := yes
        ${2}_${1}_CFLAGS := $${SRC_CFLAGS}
        ${2}_${1}_CXXFLAGS := $${SRC_CXXFLAGS}
        ${2}_${1}_DEFS := $$(addprefix -D,$${SRC_DEFS})
        ${2}_${1}_INCDIRS := $$(addprefix -I,$${SRC_INCDIRS})
    endif
endef

# ADD_LEGACY_RULE - Parametric "function" that creates legacy Makefiles
#   in the ${MAKE_DIR}/ directory.
#
#  USE WITH EVAL
#
define ADD_LEGACY_RULE
    # The makefile is named for the source file, in the "make" directory,
    # with a ".mk" extension.
    ${1}_LEGACY := $$(patsubst $${BUILD_DIR}/%,$${MAKE_DIR}/%,$${${1}_BUILD})/${1}.mk

    ALL_LEGACYMK += $${${1}_LEGACY}

    # gnu.mak needs to have a line saying "include foo.mk"
    $${MAKE_DIR}/gnu.mk: $${${1}_LEGACY}

    # The legacy makefile depends on the build Makefiles.  If they change,
    # we presume that the definitions or list of sources has changed,
    # and we need to re-build the legacy Makefile.
    #
    # We also remove leading spaces, and convert raw "build" to "${BUILD}"
    $${${1}_LEGACY}: $${${1}_MAKEFILES}
	@mkdir -p $$(dir $$@)
	${MAKE} -s LEGACY=yes INSTALL=${INSTALL} ${1} | sed \
		-e 's/^ *//' \
		-e 's, $${BUILD_DIR}, $$$${BUILD_DIR},g' > $$@

    # If we're building this legacy Makefile, then print the rules to
    # STDOUT.  The above wrapper will take care of setting "LEGACY=yes"
    ifeq "${LEGACY}" "yes"
        ifeq "$${MAKECMDGOALS}" "${1}"

            $$(info # Variable definitions)
            $$(foreach x, CFLAGS CXXFLAGS SOURCES DEPS DEFS INCDIRS OBJS \
                          LDFLAGS LDLIBS POSTMAKE LINKER POSTCLEAN INSTALLDIR \
                          POSTINSTALL PREREQS MAN BUILD PRBIN PRLIBS \
                          R_PRLIBS RELINK,\
                $$(info ${1}_$${x} := $${${1}_$${x}}))

            ifneq "$$(words $${$${1}_MAKEDIRS})" "1"
                $$(foreach d,$$(wordlist 2,$$(words $${${1}_MAKEDIRS}),$${${1}_MAKEDIRS}), \
                    $$(foreach x, CFLAGS CXXFLAGS DEFS INCDIRS,\
                $$(info ${1}_$${d}_$${x} := $${${1}_$${d}_$${x}})))
            endif

            $$(info )
            $$(info $$(call ADD_TARGET_TO_ALL,${1}))
            $$(info $$(call ADD_TARGET_RULE$${${1}_SUFFIX},${1}))
            $$(info )
            $$(info $$(call ADD_RELINK_RULE$${${1}_SUFFIX},${1}))

            ifneq "$$(filter-out $${ALL_LEGACY_INSTALLDIRS},$${${1}_INSTALLDIR})" ""
                $$(info )
                $$(info $$(call ADD_INSTALL_DIR,$$$${${1}_INSTALLDIR}))
                ALL_LEGACY_INSTALLDIRS := $${${1}_INSTALLDIR}
            endif

            $$(info )
            $$(info $$(call ADD_INSTALL_RULE$${${1}_SUFFIX},${1}))

            $$(info # When using libtool, relink with installed libdir before installation)
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

            # The magic "if" command here is for determining if we use
            # target_FOO, or target_dir_FOO in the compile rule.
            $$(foreach x, $$(filter $${CXX_SRC_EXTS},$${${1}_SOURCES}),\
                $$(info $$(call ADD_COMPILE_RULE.cxx,$${x},$$(if $${${1}_$$(dir $${x})_used},${1}_$$(dir $${x}),${1}))))

        endif
    endif

endef

ALL_LEGACYMK :=
MAKE_DIR := ${BUILD_DIR}/make

# Define a special variable that prevents the main Makefile from
# expanding variables at "eval" time.  Instead, the variables are left
# as a reference to other variables.  We can't do this all of the time,
# as it would cause the normal Make to run programs like ${foo}, instead
# of using the value of "foo".  But we *can* assign "bar := ${foo}" in
# a legacy Makefile, and then use it in a Makefile rule to run ${bar}.
#
ifeq "${LEGACY}" "yes"
    LL := $$
endif

# LEGACY_FILTER_DEPENDS - Parameterized "function" that filters the
#  dependencies.  It is a copy of FILTER_DEPENDS, with $$* changed to
#  $(basename ${1}) for portability.  The BSD Make treats $* as the
#  base filename without suffix *or* directory path.  e.g. bar/foo.c -> foo
#
define LEGACY_FILTER_DEPENDS
	@$${top_makedir}/depend2mk $${BUILD_DIR} $(dir $${MAKE_DIR}/src/${1}) \
		$${BUILD_DIR}/objs/$(basename ${1}).d \
		$${MAKE_DIR}/src/$(basename ${1}).mk
endef

# ADD_COMPILE_RULE.c - Parameterized "function" that adds a new rule
#   which says how to compile a .c file into a .o file.  This is a copy
#   of COMPILE_C_CMDS, with edits.  The GNU Make per-target variables
#   have been changed to target-specific global variables.
#
#   USE WITH EVAL
#
define ADD_COMPILE_RULE.c
    $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}: ${1}
	@$(strip mkdir -p $(dir $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}))
	$${COMPILE.c} -o $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT} -c $${CFLAGS} $${${2}_CFLAGS} \
            $${${2}_INCDIRS} $${${2}_DEFS} ${1}
	[ "$${CPP_MAKEDEPEND}" != "yes" ] || $${CPP} $${CPPFLAGS} $${${2}_INCDIRS} $${${2}_DEFS} $$< | sed \
	  -n 's,^\# *[0-9][0-9]* *"\([^"]*\)".*,$$@: \1,p' > $${BUILD_DIR}/objs/$(basename ${1}).d
$(call LEGACY_FILTER_DEPENDS,${1})

endef

# ADD_COMPILE_RULE.cxx - Parameterized "function" that adds a new rule
#   which says how to compile a .cc file into a .o file.  This is a copy
#   of COMPILE_CXX_CMDS, with edits.  The GNU Make per-target variables
#   have been changed to target-specific global variables.
#
#   USE WITH EVAL
#
define ADD_COMPILE_RULE.cxx
    $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}: ${1}
	@$(strip mkdir -p $(dir $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT}))
	$${COMPILE.cxx} -o $${BUILD_DIR}/objs/$(basename ${1}).$${OBJ_EXT} -c $${CXXFLAGS} $${${2}_CXXFLAGS} \
            $${${2}_INCDIRS} $${${2}_DEFS} ${1}
	[ "$${CPP_MAKEDEPEND}" != "yes" ] || $${CPP} $${CPPFLAGS} $${${2}_INCDIRS} $${${2}_DEFS} $$< | sed \
	  -n 's,^\# *[0-9][0-9]* *"\([^"]*\)".*,$$@: \1,p' > $${BUILD_DIR}/objs/$(basename ${1}).d
$(call LEGACY_FILTER_DEPENDS,${1})

endef

# Create a file containing the variable definitions
.PHONY: ${MAKE_DIR}/defs.mk
${MAKE_DIR}/defs.mk:
	@mkdir -p $(dir $$@)
	@${MAKE} -s LEGACY=yes INSTALL=${INSTALL} defs.mk | sed 's/^ *//' > $@

# If we're building a Makefile, have an empty target so that Make doesn't
# complain, and then do the real work in a macro.
ifneq "${LEGACY}" ""
.PHONY: defs.mk
defs.mk:

    ifeq "${LEGACY}" "yes"
        CPP_MAKEDEPEND := yes
        ifeq "${MAKECMDGOALS}" "defs.mk"
            $(info # Variable definitions)
            $(foreach x, CC CXX CPP CFLAGS CXXFLAGS LDFLAGS LDLIBS  \
                          DEFS INCDIRS MAN BUILD_DIR TARGET_DIR OBJ_EXT \
                          LIBTOOL RELINK COMPILE.c COMPILE.cxx \
                          LINK.c LINK.cxx INSTALL PROGRAM_INSTALL \
                          prefix exec_prefix bindir sbindir libdir sysconfdir \
                          localstatedir datadir mandir docdir logdir \
                          includedir top_makedir CPP_MAKEDEPEND,\
                $(info ${x} := $(value ${x})))
        endif
    endif
endif

# The GNU compatible makefile depends on the Makefiles for all of
# defined targets.
${MAKE_DIR}/gnu.mk: ${MAKE_DIR}/defs.mk
	@echo "MAKE_DIR := ${BUILD_DIR}/make" > $@
	@echo "include \$${MAKE_DIR}/defs.mk" >> $@
	@echo ".PHONY: all clean" >> $@
	@echo "all clean:" >> $@
	@echo "" >> $@
	@for x in ${ALL_LEGACYMK}; do \
		echo "include $$x" | sed -e 's, ${BUILD_DIR}/make, $${MAKE_DIR},g' >> $@; \
	done
