# Boilermake: A reusable, but flexible, boilerplate Makefile.
#
# Author: Dan Moulding <dmoulding@gmail.com> (2008)

# Caution: Don't edit this Makefile! Create your own main.mk and other
#          submakefiles, which will be included by this Makefile.
#          Only edit this if you need to modify boilermake's behavior (fix
#          bugs, add features, etc).

# Note: Parameterized "functions" in this makefile that are marked with
#       "USE WITH EVAL" are only useful in conjuction with eval. This is
#       because those functions result in a block of Makefile syntax that must
#       be evaluated after expansion. Since they must be used with eval, most
#       instances of "$" within them need to be escaped with a second "$" to
#       accomodate the double expansion that occurs when eval is invoked.

# ADD_CLEAN_RULE - Parameterized "function" that adds a new rule and phony
#   target for cleaning the specified target (removing its build-generated
#   files).
#
#   USE WITH EVAL
#
define ADD_CLEAN_RULE
    clean: clean_${1}

    .PHONY: clean_${1}
    clean_${1}:
	rm -f ${1} ${${1}_OBJS} $${${1}_OBJS:%.${OBJ_EXT}=%.[doP]}
	$${${1}_POSTCLEAN}

endef

# The dependency generator marks the object as depending on all of the
# header files.  However, if the user *deletes* a header file, Make will
# complain that there is no rule to build it.  To fix that issue, we
# parse the .d file to create rules which say "header depends on nothing".
# This causes Make to be happy, until such time as the .d file is re-created,
# to not include the deleted header.
#
%.P: %.d
	@cat $< | sed 's,${BUILD_DIR}/,${LL}$${BUILD_DIR}/,' > $@
	@sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	     -e '/^$$/ d' -e 's/$$/ :/' < $< >> $@

# DIRNAME - Parameterized "function" that outputs a rule to find the
#   directory name of the first argument.  It is defined in two forms.
#
#   The first is for use when creating "legacy.mak", which cannot use
#   GNU Make extensions.
#
#   The second is for use with modern versions of GNU Make, which uses
#   a make function instead of forking an external program.  This is
#   more efficient, and marginally faster.
#
#   USE WITH EVAL
#
ifeq "${eval}" "info"
define DIRNAME
`dirname ${1}`
endef
else
define DIRNAME
$$(dir ${1})
endef
endif

ifeq "${CC_MD}" "yes"
# ADD_DEPEND_RULE.c - Parameterized "function" that adds a new rule which
#   says that the .d file is generated automatically when the .o file is
#   created.
#
#   USE WITH EVAL
#
define ADD_DEPEND_RULE.c
    $${BUILD_DIR}/$(basename ${1}).d: $${BUILD_DIR}/$(basename ${1}).${OBJ_EXT}

endef
else				# CC_MD

# ADD_DEPEND_RULE.cc - Parameterized "function" that adds a new rule
#   which says how to create the .d file from the .cc file.  This rule
#   is used when the C compiler can't produce .d files during the
#   compilation process.
#
#   USE WITH EVAL
#
define ADD_DEPEND_RULE.c
    $${BUILD_DIR}/$(basename ${1}).d: ${1}
	@mkdir -p $(call DIRNAME,$$@)
	$${CPP} $${CPPFLAGS} $${${2}_INCDIRS} $${${2}_DEFS} $$< \
                 | sed -n 's,^\# *[0-9][0-9]* *"\([^"]*\)".*,$${BUILD_DIR}/$(basename ${1}).${OBJ_EXT}: \1,p' \
                 | sed -e 's,: /usr\(.*\)$$$$,: ,' -e 's,: <\(.*\)$$$$,: ,' -e 's,^.*: $$$$,,' | sort | uniq > $$@

endef				# ADD_DEPEND_RULE

endif				# CC_MD

# ADD_COMPILE_RULE.c - Parameterized "function" that adds a new rule
#   which says how to compile a .c file into a .o file.
#
#   There is normally no need for object-specific rules, as a generic
#   rule could achieve the same result.  Instead, this rule is used as
#   a template to create legacy Makefiles.
#
#   USE WITH EVAL
#
define ADD_COMPILE_RULE.c
    $${BUILD_DIR}/$(basename ${1}).${OBJ_EXT}: ${1}
	@mkdir -p $(call DIRNAME,$$@)
	$${COMPILE_CC} -o $$@ -c $${CFLAGS} $${${2}_CFLAGS} \
            $${${2}_INCDIRS} $${${2}_DEFS} $$<

endef


# ADD_COMPILE_RULE.cc - Parameterized "function" that adds a new rule
#   which says how to compile a .cc file into a .o file.
#
#   There is normally no need for object-specific rules, as a generic
#   rule could achieve the same result.  Instead, this rule is used as
#   a template to create legacy Makefiles.
#
#   USE WITH EVAL
#
define ADD_COMPILE_RULE.cc
    $${BUILD_DIR}/$(basename ${1}).${OBJ_EXT}: ${1}
	@mkdir -p $(call DIRNAME,$$@)
	$${COMPILE_CXX} -o $$@ -c $${CXXFLAGS} $${${2}_CXXFLAGS} \
            $${${2}_INCDIRS} $${${2}_DEFS} $$<

endef

# ADD_TARGT_RULE.* - Parameterized "functions" that adds a new target to the
#   Makefile.  There should be one ADD_TARGET_RULE definition for each
#   type of target that is used in the build.  
#
#   New rules can be added by copying one of the existing ones, and
#   replacing the line after the "mkdir"
#

# ADD_TARGET_RULE.exe - Build an executable target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.exe
    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $(call DIRNAME,$$@)
	    $${${1}_LINKER} -o ${1} $${LDFLAGS} $${${1}_LDFLAGS} \
	        $${${1}_OBJS} $${${1}_PRLIBS} $${LDLIBS} $${${1}_LDLIBS}
	    $${${1}_POSTMAKE}

endef

# ADD_TARGET_RULE.a - Build a static library target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.a
    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $(call DIRNAME,$$@)
	    $${AR} $${ARFLAGS} ${1} $${${1}_OBJS}
	    $${${1}_POSTMAKE}

endef

# ADD_TARGET_RULE.so - Build a ".so" target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.so
$(error Please add rules to build a ".so" file.)
endef

# ADD_TARGET_RULE.dll - Build a ".dll" target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.dll
$(error Please add rules to build a ".dll" file.)
endef

# ADD_TARGET_RULE.dylib - Build a ".dylib" target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.dylib
$(error Please add rules to build a ".dylib" file.)
endef

# ADD_TARGET_RULE.la - Build a ".la" target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.la
    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $(call DIRNAME,$$@)
	    $${${1}_LINKER} -o ${1} $${LDFLAGS} $${${1}_LDFLAGS} \
	        $${${1}_OBJS} $${LDLIBS} $${${1}_LDLIBS}
	    $${${1}_POSTMAKE}

endef

# ADD_INSTALL_RULE.* - Parameterized "functions" that adds a new
#   installation to the Makefile.  There should be one ADD_INSTALL_RULE
#   definition for each type of target that is used in the build.
#
#   New rules can be added by copying one of the existing ones, and
#   replacing the line after the "mkdir"
#

# ADD_INSTALL_RULE.exe - Parameterized "function" that adds a new rule
#   and phony target for installing an executable.
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.exe
    install: $${${1}_INSTALLDIR}/$(notdir ${1})

    $${${1}_INSTALLDIR}/$(notdir ${1}): ${1}
	@mkdir -p $${${1}_INSTALLDIR}
	$${PROGRAM_INSTALL} -c -m 755 ${1} $${${1}_INSTALLDIR}/
	$${${1}_POSTINSTALL}

endef

# ADD_INSTALL_RULE.a - Parameterized "function" that adds a new rule
#   and phony target for installing a static library
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.a
    install: $${${1}_INSTALLDIR}/$(notdir ${1})

    $${${1}_INSTALLDIR}/$(notdir ${1}): ${1}
	@mkdir -p $${${1}_INSTALLDIR}
	$${PROGRAM_INSTALL} -c -m 755 ${1} $${${1}_INSTALLDIR}/
	$${${1}_POSTINSTALL}

endef

# ADD_INSTALL_RULE.la - Parameterized "function" that adds a new rule
#   and phony target for installing a libtool library
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.la
    install: $${${1}_INSTALLDIR}/$(notdir ${1})

    $${${1}_INSTALLDIR}/$(notdir ${1}): ${1}
	@mkdir -p $${${1}_INSTALLDIR}
	$${PROGRAM_INSTALL} -c -m 755 ${1} $${${1}_INSTALLDIR}/
	$${${1}_POSTINSTALL}

endef

# ADD_INSTALL_RULE.man - Parameterized "function" that adds a new rule
#   and phony target for installing a "man" page.  It will take care of
#   installing it into the correct subdirectory of "man".
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.man
    install: ${2}/$(notdir ${1})

    ${2}/$(notdir ${1}): ${1}
	@mkdir -p ${2}/
	$${PROGRAM_INSTALL} -c -m 644 ${1} ${2}/

endef

# LIBTOOL_ENDINGS - Given a library ending in ".a" or ".so", replace that
#   extension with ".la".
#
define LIBTOOL_ENDINGS
$(patsubst %.a,%.la,$(patsubst %.so,%.la,${1}))
endef

# CANONICAL_PATH - Given one or more paths, converts the paths to the canonical
#   form. The canonical form is the path, relative to the project's top-level
#   directory (the directory from which "make" is run), and without
#   any "./" or "../" sequences. For paths that are not  located below the
#   top-level directory, the canonical form is the absolute path (i.e. from
#   the root of the filesystem) also without "./" or "../" sequences.
define CANONICAL_PATH
$(patsubst ${CURDIR}/%,%,$(abspath ${1}))
endef

# INCLUDE_SUBMAKEFILE - Parameterized "function" that includes a new
#   "submakefile" fragment into the overall Makefile. It also recursively
#   includes all submakefiles of the specified submakefile fragment.
#
#   USE WITH EVAL
#
define INCLUDE_SUBMAKEFILE
    # Initialize all variables that can be defined by a makefile fragment, then
    # include the specified makefile fragment.
    TARGET :=
    TGT_LDFLAGS :=
    TGT_LDLIBS :=
    TGT_LINKER :=
    TGT_POSTCLEAN :=
    TGT_POSTMAKE :=
    TGT_PREREQS :=
    TGT_POSTINSTALL :=
    TGT_INSTALLDIR := ..

    MAN :=

    SOURCES :=
    SRC_CFLAGS :=
    SRC_CXXFLAGS :=
    SRC_DEFS :=
    SRC_INCDIRS :=

    SUBMAKEFILES :=

    # A directory stack is maintained so that the correct paths are used as we
    # recursively include all submakefiles. Get the makefile's directory and
    # push it onto the stack.
    DIR := $(call CANONICAL_PATH,$(dir ${1}))
    DIR_STACK := $$(call PUSH,$${DIR_STACK},$${DIR})

    include ${1}

    # Initialize internal local variables.
    OBJS :=

    # Ensure that valid values are set for BUILD_DIR and TARGET_DIR.
    ifeq "$$(strip $${BUILD_DIR})" ""
        BUILD_DIR := ${RR}build
    else ifeq "${_BUILD_DIR}" ""
        BUILD_DIR := ${RR}${BUILD_DIR}
    endif
    ifeq "$$(strip $${TARGET_DIR})" ""
        TARGET_DIR := ${RR}
    else ifeq "${_TARGET_DIR}" ""
        TARGET_DIR := ${RR}${TARGET_DIR}/
    endif
    _BUILD_DIR := yes
    _TARGET_DIR := yes

    # Determine which target this makefile's variables apply to. A stack is
    # used to keep track of which target is the "current" target as we
    # recursively include other submakefiles.
    ifneq "$$(strip $${TARGET})" ""

        ifneq "${LIBTOOL}" ""
            TARGET_NOLIBTOOL := $${TARGET}
            TARGET := $$(call LIBTOOL_ENDINGS,$${TARGET})
            ifeq "$${TARGET_NO_LIBTOOL}" "$${TARGET}"
                TARGET_NO_LIBTOOL := 
            endif
            TGT_PREREQS := $$(call LIBTOOL_ENDINGS,$${TGT_PREREQS})
        endif

        # This makefile defined a new target. Target variables defined by this
        # makefile apply to this new target. Initialize the target's variables.
        TGT := $$(strip $${TARGET_DIR}$${TARGET})
        ALL_TGTS += $${TGT}

        # Add top-level target pointing to the full path of the
        # target.  This lets us make a target from any subdirectory
        # by simply doing "make target".  We also add a NON-libtool
        # target, so that build systems using boilermake can use
        # "make libfoo.a", even when libtool is defined.
        ifneq "$${TARGET}" "$${TGT}"
            $$(${eval} $${TARGET}:$${TGT})
        endif
        ifneq "$${TARGET_NOLIBTOOL}" ""
            $$(${eval} $${TARGET_NOLIBTOOL}:$${TGT})
        endif

        $${TGT}_LDFLAGS := $${TGT_LDFLAGS}
        $${TGT}_LDLIBS := $${TGT_LDLIBS}
        $${TGT}_POSTMAKE := $${TGT_POSTMAKE}
        $${TGT}_LINKER := $${TGT_LINKER}
        $${TGT}_POSTCLEAN := $${TGT_POSTCLEAN}
        $${TGT}_POSTINSTALL := $${TGT_POSTINSTALL}

        $${TGT}_PREREQS := $$(addprefix $${TARGET_DIR},$${TGT_PREREQS})
        $${TGT}_PRLIBS := $$(filter %.a %.so %.la,$${$${TGT}_PREREQS})
        $${TGT}_DEPS :=
        $${TGT}_OBJS :=
        $${TGT}_SOURCES :=
        $${TGT}_MAN := $${MAN}

        $${TGT}_SUFFIX := $$(if $$(suffix $${TGT}),$$(suffix $${TGT}),.exe)

        # Figure out which target rule to use for installation.
        ifeq "$${$${TGT}_SUFFIX}" ".exe"
            ifeq "$${TGT_INSTALLDIR}" ".."
                TGT_INSTALLDIR := ${LL}$${bindir}
            endif
        else 
            ifeq "$${TGT_INSTALLDIR}" ".."
                TGT_INSTALLDIR := ${LL}$${libdir}
            endif
        endif

        $${TGT}_INSTALLDIR := ${LL}$${DESTDIR}$${TGT_INSTALLDIR}
    else
        # The values defined by this makefile apply to the the "current" target
        # as determined by which target is at the top of the stack.
        TGT := $$(strip $$(call PEEK,$${TGT_STACK}))
    endif

    # Push the current target onto the target stack.
    TGT_STACK := $$(call PUSH,$${TGT_STACK},$${TGT})

    ifneq "$$(strip $${SOURCES})" ""
        # This makefile builds one or more objects from source. Validate the
        # specified sources against the supported source file types.
        BAD_SRCS := $$(strip $$(filter-out $${ALL_SRC_EXTS},$${SOURCES}))
        ifneq "$${BAD_SRCS}" ""
            $$(error Unsupported source file(s) found in ${1} [$${BAD_SRCS}])
        endif

        # Qualify and canonicalize paths.
        SOURCES     := $$(call QUALIFY_PATH,$${DIR},$${SOURCES})
        SOURCES     := $$(call CANONICAL_PATH,$${SOURCES})
        SRC_INCDIRS := $$(call QUALIFY_PATH,$${DIR},$${SRC_INCDIRS})
        SRC_INCDIRS := $$(call CANONICAL_PATH,$${SRC_INCDIRS})

        # Save the list of source files for this target.
        $${TGT}_SOURCES += $${SOURCES}

        # Convert the source file names to their corresponding object file
        # names.
        OBJS := $$(addprefix ${LL}$${BUILD_DIR}/,\
                   $$(addsuffix .${OBJ_EXT},$$(basename $${SOURCES})))

        # Add the objects to the current target's list of objects, and create
        # target-specific variables for the objects based on any source
        # variables that were defined.
        $${TGT}_OBJS     += $${OBJS}
        $${TGT}_DEPS     += $${OBJS:%.${OBJ_EXT}=%.P}
        $${TGT}_CFLAGS   := $${SRC_CFLAGS}
        $${TGT}_CXXFLAGS := $${SRC_CXXFLAGS}
        $${TGT}_DEFS     := $$(addprefix -D,$${SRC_DEFS})
        $${TGT}_INCDIRS  := $$(addprefix -I,$${SRC_INCDIRS})
    endif

    ifneq "$$(strip $${SUBMAKEFILES})" ""
        # This makefile has submakefiles. Recursively include them.
        $$(foreach MK,$${SUBMAKEFILES},\
           $$(eval $$(call INCLUDE_SUBMAKEFILE,\
                      $$(call CANONICAL_PATH,\
                         $$(call QUALIFY_PATH,$${DIR},$${MK})))))
    endif

    # Reset the "current" target to it's previous value.
    TGT_STACK := $$(call POP,$${TGT_STACK})

    # If we're about to change targets, create the rules for the target
    ifneq "$${TGT}" "$$(call PEEK,$${TGT_STACK})"
        # Choose the correct linker.
	ifeq "$$(strip $$(filter $${CXX_SRC_EXTS},$${$${TGT}_SOURCES}))" ""
            ifeq "$${$${TGT}_LINKER}" ""
                $${TGT}_LINKER := ${LL}$${LINKER_CC}
            endif
        else
            ifeq "$${$${TGT}_LINKER}" ""
                $${TGT}_LINKER := ${LL}$${LINKER_CXX}
            endif
        endif


        # Add the target to the default list of targets to be made
        ifneq "${eval}" "eval"
            $$(info #)
            $$(info # Rules for $${TGT})
            $$(info all: $${TGT})
            $$(info )

            $$(foreach x, CFLAGS CXXFLAGS SOURCES DEPS DEFS INCDIRS OBJS \
                          LDFLAGS LDLIBS POSTMAKE LINKER POSTCLEAN INSTALLDIR \
                          POSTINSTALL PREREQS PRLIBS MAN,\
               $$(info $${TGT}_$${x} := $${$${TGT}_$${x}}))
            $$(info )
        endif

        # If the C compiler generates dependencies, print rules saying
        # that the .d file depends on the .o file.
        $$(foreach C,$${$${TGT}_SOURCES},\
            $$(${eval} $$(call ADD_DEPEND_RULE.c,$${C},$${TGT})))

        $$(foreach C,$$(filter $${CXX_SRC_EXTS},$${$${TGT}_SOURCES}),\
            $$(${eval} $$(call ADD_COMPILE_RULE.cc,$${C},$${TGT})))

        $$(foreach C,$$(filter $${C_SRC_EXTS},$${$${TGT}_SOURCES}),\
            $$(${eval} $$(call ADD_COMPILE_RULE.c,$${C},$${TGT})))

        # For dependency tracking to work, we still add all targets
        # to the build system.

        # add rules to build the target
        $$(${eval} $$(call ADD_TARGET_RULE$${$${TGT}_SUFFIX},$${TGT}))

        # If the current directory is the a subdir of the one we're
        # building in, then build it.  We check for a subdir by
        # adding "_xyz" to the directory, and then substituting "_xyxROOT"
        # with ROOT.  If the result is DIR, then we're in a subdir.
        ifeq "$$(abspath $${DIR})" "$$(abspath ${root}/$${SUBDIR})$$(subst _xyz$$(abspath ${root}/$${SUBDIR}),,_xyz$$(abspath $${DIR}))"
            # Add the target to the default list of targets to be made
            ifeq "${eval}" "eval"
                all: $${TGT}
             endif

            # do installs only if we have an installation program.
            ifneq "${INSTALL}" ""
                # add rules to install the target
                ifneq "$${$${TGT}_INSTALLDIR}" ""
                    $$(${eval} $$(call ADD_INSTALL_RULE$${$${TGT}_SUFFIX},$${TGT}))
                endif
            endif

            # add rules to install the MAN pages.
            ifneq "$$(strip $${MAN})" ""
                ifeq "$${mandir}" ""
                    $$(error You must define 'mandir' in order to be able to install MAN pages.)
                endif

                MAN     := $$(call QUALIFY_PATH,$${DIR},$${MAN})
                MAN     := $$(call CANONICAL_PATH,$${MAN})

                $$(foreach PAGE,$${MAN},\
                    $$(${eval} $$(call ADD_INSTALL_RULE.man,$${PAGE},\
                      ${LL}$${DESTDIR}${LL}$${mandir}/man$$(subst .,,$$(suffix $${PAGE})))))
            endif

            # add rules to clean the output files
            $$(${eval} $$(call ADD_CLEAN_RULE,$${TGT}))
        endif

        # include the dependency files of the target
        ifneq ($(MAKECMDGOALS),clean)
            $$(eval -include $${$${TGT}_DEPS})
        endif

        ifneq "${eval}" "eval"
            $$(foreach x, $$(subst ${LL}$${BUILD_DIR},$${BUILD_DIR},$${$${TGT}_DEPS}),\
                $$(info # )\
                $$(info # Dependencies from $${x})\
                $$(info -include $${x})\
                $$(info ))
        endif
    endif

    TGT := $$(call PEEK,$${TGT_STACK})

    # Reset the "current" directory to it's previous value.
    DIR_STACK := $$(call POP,$${DIR_STACK})
    DIR := $$(call PEEK,$${DIR_STACK})
endef

# MIN - Parameterized "function" that results in the minimum lexical value of
#   the two values given.
define MIN
$(firstword $(sort ${1} ${2}))
endef

# PEEK - Parameterized "function" that results in the value at the top of the
#   specified colon-delimited stack.
define PEEK
$(lastword $(subst :, ,${1}))
endef

# POP - Parameterized "function" that pops the top value off of the specified
#   colon-delimited stack, and results in the new value of the stack. Note that
#   the popped value cannot be obtained using this function; use peek for that.
define POP
${1:%:$(lastword $(subst :, ,${1}))=%}
endef

# PUSH - Parameterized "function" that pushes a value onto the specified colon-
#   delimited stack, and results in the new value of the stack.
define PUSH
${2:%=${1}:%}
endef

# QUALIFY_PATH - Given a "root" directory and one or more paths, qualifies the
#   paths using the "root" directory (i.e. appends the root directory name to
#   the paths) except for paths that are absolute.
define QUALIFY_PATH
$(addprefix ${1}/,$(filter-out /%,${2})) $(filter /%,${2})
endef

###############################################################################
#
# Start of Makefile Evaluation
#
###############################################################################

# Older versions of GNU Make lack capabilities needed by boilermake.
# With older versions, "make" may simply output "nothing to do", likely leading
# to confusion. To avoid this, check the version of GNU make up-front and
# inform the user if their version of make doesn't meet the minimum required.
MIN_MAKE_VERSION := 3.81
MIN_MAKE_VER_MSG := boilermake requires GNU Make ${MIN_MAKE_VERSION} or greater
ifeq "${MAKE_VERSION}" ""
    $(info GNU Make not detected)
    $(error ${MIN_MAKE_VER_MSG})
endif
ifneq "${MIN_MAKE_VERSION}" "$(call MIN,${MIN_MAKE_VERSION},${MAKE_VERSION})"
    $(info This is GNU Make version ${MAKE_VERSION})
    $(error ${MIN_MAKE_VER_MSG})
endif

# If this ISN'T the top-level Makefile, then find out where it is
# and set the "root ref" variable.  If we're at the top, set the root ref
# to be empty.
#
RR := $(dir $(word 2, ${MAKEFILE_LIST}))
ifeq "${RR}" "./"
  RR := 
else ifeq "${RR}" "$(call CANONICAL_PATH,${RR})/"
  RR := 
else
  RR := $(patsubst %//,%/,${RR})
endif

# Look in the target directory for libraries
ifneq "${RR}${TARGET_DIR}" ""
    LDFLAGS += -L${RR}${TARGET_DIR}
else
    LDFLAGS += -L.
endif

root := $(patsubst ${CURDIR}/%,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
SUBDIR := $(subst ${root}/,,${PWD})
ifeq "${root}" "${SUBDIR}"
    SUBDIR :=
endif

# Ensure DESTDIR has a trailing /.  We do this by adding a (possibly)
# second one, and then replacing the doubled one with a single one.
ifneq "${DESTDIR}" ""
    DESTDIR := $(patsubst %//,%/,${DESTDIR}/)
endif

# Define the source file extensions that we know how to handle.
C_SRC_EXTS := %.c
CXX_SRC_EXTS := %.C %.cc %.cp %.cpp %.CPP %.cxx %.c++
ALL_SRC_EXTS := ${C_SRC_EXTS} ${CXX_SRC_EXTS}

# Initialize global variables.
ALL_TGTS :=
DEFS :=
DIR_STACK :=
INCDIRS :=
TGT_STACK :=

# Define the "all" target (which simply builds all user-defined targets) as the
# default goal.
.PHONY: all clean install
all clean install:

# Automatically set some variables if we're using libtool.  Object files
# are "foo.lo", not "foo.o".  Compilers are "libtool ... cc", not "cc".
#
ifeq "${LIBTOOL}" ""
OBJ_EXT := o
COMPILE_CC = ${CC}
COMPILE_CXX = ${CXX}
LINKER_CC = ${CC}
LINKER_CXX = ${CXX}
PROGRAM_INSTALL := ${INSTALL}
else
OBJ_EXT := lo
COMPILE_CC = ${LIBTOOL} --mode=compile ${CC}
COMPILE_CXX = ${LIBTOOL} --mode=compile ${CXX}
LINKER_CC = ${LIBTOOL} --mode=link ${CC}
LINKER_CXX = ${LIBTOOL} --mode=link ${CXX}
PROGRAM_INSTALL := ${LIBTOOL} --mode=install ${INSTALL}

# Build jlibtool if it wasn't already built.
ifeq "$(abspath ${LIBTOOL})" "$(abspath ${top_srcdir}/jlibtool)"

# This rule means that jlibtool is build BEFORE any other targets,
# which means that we can use it to build the later targets.
all: ${top_srcdir}/jlibtool

# Note that we need to use a compilation rule that does NOT include
# referencing ${LIBTOOL}, as we don't have a jlibtool binary!
jlibtool ${top_srcdir}/jlibtool: ${top_srcdir}/jlibtool.c
	${CC} $< -o $@

# do "clean" of jlibtool ONLY
ifeq "${SUBDIR}" ""
clean: jlibtool_clean

.PHONY: jlibtool_clean
jlibtool_clean:
	rm -f ${top_srcdir}/jlibtool
endif
endif

# If there is an installation directory, add dynamic library flags
# to the build.
ifneq "${libdir}" ""
    LDFLAGS += -rpath ${libdir} -export-dynamic
else
    LDFLAGS += -static
endif

endif	# LIBTOOl was defined

# Give an error if we can't do "make install", rather than saying
# "nothing to do".
ifeq "${INSTALL}" ""
install: install_ERROR

.PHONY: install_ERROR
install_ERROR:
	@echo Please define INSTALL in order to enable the installation rules.
	@exit 1
endif

# FIXME: Check for GCC
ifeq "${CC_MD}" "yes"
CFLAGS += -MD
CXXFLAGS += -MD
endif

# Set to "info" for legacy makefile goodness!
# Special macro to enable creating legacy Makefiles.  We *could* simply
# output the full pathnames for every single rule.  However, that would
# make it difficult to edit the resulting Makefile.  Instead, we define
# a special variable which makes the EVAL rules above print out references
# to the variable.  The other rules also print out "variable := value".
#
ifeq "${eval}" "info"
    LL := $$
    BUILD_DIR := build

    $(info # -*- Makefile -*-)
    $(info # )
    $(info # High level definitions)
    $(foreach x,CC CXX LIBTOOL COMPILE_CC COMPILE_CXX CFLAGS CXXFLAGS \
                BUILD_DIR LINKER_CC LINKER_CXX LDFLAGS LIBS INSTALL \
                PROGRAM_INSTALL prefix  exec_prefix sysconfdir localstatedir \
                libdir bindir sbindir  datarootdir docdir mandir datadir \
                logdir includedir,\
        $(info ${x} = $(value ${x})))
    $(info )
    $(shell touch .foo)

# The next few hacks are here to prevent make from printing
# "Nothing to be done".  It's ugly, but more portable than "egrep -v"
all: .bar

.bar: .foo
	@touch $@

else
    eval=eval
endif

# Include the main user-supplied submakefile. This also recursively includes
# all other user-supplied submakefiles.
$(eval $(call INCLUDE_SUBMAKEFILE,${RR}main.mk))

# This depends on all of the generated ".P" files, which in turn create
# dependencies on all of the headers && source files.
legacy.mak: ${top_srcdir}/boiler.mk ${top_srcdir}/Makefile \
            $(foreach x,${ALL_TGTS},${${x}_DEPS})
	${MAKE} eval=info | sed 's/    //' | awk '{if ($$1 == "-include") {file=$$2;while (i = getline < file) {print;}} else { print $$0 }}' > $@
	@rm -f .bar .foo

clean: legacy_clean

.PHONY: legacy_clean
legacy_clean:
	@rm -f legacy.mak
