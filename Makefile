# boilermake: A reusable, but flexible, boilerplate Makefile.
#
# Author: Dan Moulding <dmoulding@gmail.com> (2008)

# Caution: Don't edit this Makefile! Create your own main.mk and other
#          submakefiles, which will be included by this Makefile.
#          Only edit this if you need to modify boilermake's behavior (fix
#          bugs, add features, etc).

# Older versions og GNU Make lack capabilities needed by this system.
# Instead, running "make" returns "nothing to do".  In order to tell
# the user what really happened, we check the version of GNU make.
#
gnu_need := 3.81
gnu_ok := $(filter $(gnu_need),$(firstword $(sort $(MAKE_VERSION) $(gnu_need))))
ifeq ($(gnu_ok),)
$(error Your version of GNU Make is too old.  We need at least $(gnu_need))
endif

ifeq "${LIBTOOL}" ""
OBJ_EXT = o
PROGRAM_CC = ${CC}
PROGRAM_CXX = ${CXX}
else
OBJ_EXT = lo
PROGRAM_CC = ${LIBTOOL} --mode=compile ${CC}
PROGRAM_CXX = ${LIBTOOL} --mode=compile ${CXX}
endif

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
	$$(strip rm -f ${1} ${${1}_OBJS} $${${1}_OBJS:%.${OBJ_EXT}=%.[doP]})
	$${${1}_POSTCLEAN}
endef

# ADD_OBJECT_RULE - Parameterized "function" that adds a pattern rule, using
#   the commands from the second argument, for building object files from
#   source files with the filename extension specified in the first argument.
#
#   USE WITH EVAL
#
define ADD_OBJECT_RULE
$${BUILD_DIR}/%.${OBJ_EXT}: ${1}
	${2}
endef

# ADD_TARGET_RULE.* - Parameterized "functions" that adds a new target to the
#   Makefile.  There should be one ADD_TARGET_RULE definition for each
#   type of target that is used in the build.  
#
#   New rules can be added by copying one of the existing ones, and
#   replacing the line containing $$(strip ...)
#

# ADD_TARGET_RULE.exe - Build an executable target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.exe
    # Add a target for linking an executable. First, attempt to select the
    # appropriate front-end to use for linking. This might not choose the
    # right one (e.g. if linking with a C++ static library, but all other
    # sources are C sources), so the user makefile is allowed to specify a
    # linker to be used for each target.
    ifeq "$$(strip $${${1}_LINKER})" ""
        # No linker was explicitly specified to be used for this target. If
        # there are any C++ sources for this target, use the C++ compiler.
        # For all other targets, default to using the C compiler.
        ifneq "$$(strip $$(filter $${CXX_SRC_EXTS},$${${1}_SOURCES}))" ""
            ${1}: TGT_LINKER = $${CXX}
        else
            ${1}: TGT_LINKER = $${CC}
        endif
    endif

    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $$(dir $$@)
	    $$(strip $${TGT_LINKER} -o ${1} $${LDFLAGS} $${TGT_LDFLAGS} \
	        $${${1}_OBJS} $${LDLIBS} $${TGT_LDLIBS})
	    $${TGT_POSTMAKE}
endef

# ADD_TARGET_RULE.a - Build a static library target.
#
#   USE WITH EVAL
#
define ADD_TARGET_RULE.a
    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $$(dir $$@)
	    $$(strip $${AR} $${ARFLAGS} ${1} $${${1}_OBJS})
	    $${TGT_POSTMAKE}
endef

#  If we're using libtool, re-define all of the rules to use it,
#  rather than the above commands.
#
ifneq "${LIBTOOL}" ""
define ADD_TARGET_RULE.la
    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $$(dir $$@)
	    ${LIBTOOL} --mode=link -module ${CC} -o ${1} $${LDFLAGS} $${TGT_LDFLAGS} \
	        $${${1}_OBJS} $${LDLIBS} $${TGT_LDLIBS}
	    $${TGT_POSTMAKE}
endef

define ADD_TARGET_RULE.exe
    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $$(dir $$@)
	    ${LIBTOOL} --mode=link ${CC} -o ${1} $${LDFLAGS} $${TGT_LDFLAGS} \
	        $${${1}_OBJS} $${LDLIBS} $${TGT_LDLIBS}
	    $${TGT_POSTMAKE}
endef
endif


# CANONICAL_PATH - Given one or more paths, converts the paths to the canonical
#   form. The canonical form is the path, relative to the project's top-level
#   directory (the directory from which "make" is run), and without
#   any "./" or "../" sequences. For paths that are not  located below the
#   top-level directory, the canonical form is the absolute path (i.e. from
#   the root of the filesystem) also without "./" or "../" sequences.
define CANONICAL_PATH
$(patsubst ${CURDIR}/%,%,$(abspath ${1}))
endef

define LIBTOOL_ENDINGS
$(patsubst %.a,%.la,$(patsubst %.so,%.la,${1}))
endef

# COMPILE_C_CMDS - Commands for compiling C source code.
define COMPILE_C_CMDS
	@mkdir -p $(dir $@)
	$(strip ${PROGRAM_CC} -o $@ -c -MD ${CFLAGS} ${SRC_CFLAGS} ${INCDIRS} \
	    ${SRC_INCDIRS} ${SRC_DEFS} ${DEFS} $<)
	@cp ${BUILD_DIR}/$*.d ${BUILD_DIR}/$*.P; \
	 sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	     -e '/^$$/ d' -e 's/$$/ :/' < ${BUILD_DIR}/$*.d \
	     >> ${BUILD_DIR}/$*.P; \
	 rm -f ${BUILD_DIR}/$*.d
endef

# COMPILE_CXX_CMDS - Commands for compiling C++ source code.
define COMPILE_CXX_CMDS
	@mkdir -p $(dir $@)
	$(strip ${PROGRAM_CXX} -o $@ -c -MD ${CXXFLAGS} ${SRC_CXXFLAGS} ${INCDIRS} \
	    ${SRC_INCDIRS} ${SRC_DEFS} ${DEFS} $<)
	@cp ${BUILD_DIR}/$*.d ${BUILD_DIR}/$*.P; \
	 sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	     -e '/^$$/ d' -e 's/$$/ :/' < ${BUILD_DIR}/$*.d \
	     >> ${BUILD_DIR}/$*.P; \
	 rm -f ${BUILD_DIR}/$*.d
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

    SOURCES :=
    SRC_CFLAGS :=
    SRC_CXXFLAGS :=
    SRC_DEFS :=
    SRC_INCDIRS :=

    SUBMAKEFILES :=

    include ${1}

    # Initialize internal local variables.
    OBJS :=

    # Ensure that valid values are set for BUILD_DIR and TARGET_DIR.
    ifeq "$$(strip $${BUILD_DIR})" ""
        BUILD_DIR := build
    endif
    ifeq "$$(strip $${TARGET_DIR})" ""
        TARGET_DIR := .
    endif

    # A directory stack is maintained so that the correct paths are used as we
    # recursively include all submakefiles. Get the makefile's directory and
    # push it onto the stack.
    DIR := $(call CANONICAL_PATH,$(dir ${1}))
    DIR_STACK := $$(call PUSH,$${DIR_STACK},$${DIR})

    # Determine which target this makefile's variables apply to. A stack is
    # used to keep track of which target is the "current" target as we
    # recursively include other submakefiles.
    ifneq "$$(strip $${TARGET})" ""
        # This makefile defined a new target. Target variables defined by this
        # makefile apply to this new target. Initialize the target's variables.

        ifneq "${LIBTOOL}" ""
            TARGET := $$(call LIBTOOL_ENDINGS,$${TARGET})
        endif

        TGT := $$(strip $${TARGET_DIR}/$${TARGET})
        $${TGT}: TGT_LDFLAGS := $${TGT_LDFLAGS}
        $${TGT}: TGT_LDLIBS := $${TGT_LDLIBS}
        $${TGT}: TGT_LINKER := $${TGT_LINKER}
        $${TGT}: TGT_POSTMAKE := $${TGT_POSTMAKE}
        $${TGT}_LINKER := $${TGT_LINKER}
        $${TGT}_POSTCLEAN := $${TGT_POSTCLEAN}

        ifneq "${LIBTOOL}" ""
            TGT_PREREQS := $$(call LIBTOOL_ENDINGS,$${TGT_PREREQS})
        endif

        $${TGT}_PREREQS := $$(addprefix $${TARGET_DIR}/,$${TGT_PREREQS})
        $${TGT}_DEPS :=
        $${TGT}_OBJS :=
        $${TGT}_SOURCES :=
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
        OBJS := $$(addprefix $${BUILD_DIR}/,\
                   $$(addsuffix .${OBJ_EXT},$$(basename $${SOURCES})))

        # Add the objects to the current target's list of objects, and create
        # target-specific variables for the objects based on any source
        # variables that were defined.
        $${TGT}_OBJS += $${OBJS}
        $${TGT}_DEPS += $${OBJS:%.${OBJ_EXT}=%.P}
        $${OBJS}: SRC_CFLAGS := $${SRC_CFLAGS}
        $${OBJS}: SRC_CXXFLAGS := $${SRC_CXXFLAGS}
        $${OBJS}: SRC_DEFS := $$(addprefix -D,$${SRC_DEFS})
        $${OBJS}: SRC_INCDIRS := $$(addprefix -I,$${SRC_INCDIRS})
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
        # If we're building in the root, DIR==DIR, and we add the target.
        # if we're building an a subdirectory, and delete/add of SUBDIR
        # to DIR==DIR, then we're building in the RIGHT subdirectory.
        #
        # Building in a subdirectory means building ONLY the targets
        # in that directory, BUT also building their dependencies
        # It also means cleaning ONLY the targets in the subdirectory.
        #
        ifeq "$$(abspath $${DIR})" "$$(abspath $${SUBDIR})$$(subst _xyz$$(abspath $${SUBDIR}),,_xyz$$(abspath $${DIR}))"
            ALL_TGTS += $${TGT}

            # Add the target to the default list of targets to be made
            all: $${TGT}

            # add rules to clean the output files
            $$(eval $$(call ADD_CLEAN_RULE,$${TGT}))
        endif

        # For dependency tracking to work, we still add all targets
        # to the build system.

        # Figure out which target rule to use for building.
	TGT_SUFFIX := $$(suffix $${TGT})
        ifeq "$${TGT_SUFFIX}" ""
            TGT_SUFFIX := .exe
        endif

        # add rules to build the target
        $$(eval $$(call ADD_TARGET_RULE$${TGT_SUFFIX},$${TGT}))

        # include the dependency files of the target
        $$(eval -include $${$${TGT}_DEPS})
    endif

    TGT := $$(call PEEK,$${TGT_STACK})

    # Reset the "current" directory to it's previous value.
    DIR_STACK := $$(call POP,$${DIR_STACK})
    DIR := $$(call PEEK,$${DIR_STACK})
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

# Ensure that these are defined as PHONY before anything else happens
.PHONY: clean all

# Allow subdirectories to have a "Makefile" that contains nothing more
# than "include ../../../../boiler.mk".  If we notice that the current
# directory doesn't have a "main.mk" file, we walk back up the
# directory tree until we find one.
#
MAIN_MK := main.mk
ifeq ($(wildcard ${MAIN_MK}),)
_sp :=
_sp +=
_walk = $(if $1,$(wildcard /$(subst $(_sp),/,$1)/$2) $(call _walk,$(wordlist 2,$(words $1),x $1),$2))
_find = $(firstword $(call _walk,$(strip $(subst /, ,$1)),$2))
_ROOT := $(patsubst %/${MAIN_MK},%,$(call _find,$(CURDIR),${MAIN_MK}))

ifeq (${_ROOT},)
$(error Failed to find a top-level "main.mk" file)
endif

_RELATIVE=$(subst ${_ROOT}/,,${PWD})


#
#  We're in a subdirectory, go back up to the root, and re-build
#  everything from there.
#
all:
	@$(MAKE) -C ${_ROOT} SUBDIR=${_RELATIVE}

clean:
	@$(MAKE) -C ${_ROOT} SUBDIR=${_RELATIVE} clean
else

# Include the main user-supplied submakefile. This also recursively includes
# all other user-supplied submakefiles.
$(eval $(call INCLUDE_SUBMAKEFILE,${MAIN_MK}))

# Perform post-processing on global variables as needed.
DEFS := $(addprefix -D,${DEFS})
INCDIRS := $(addprefix -I,$(call CANONICAL_PATH,${INCDIRS}))

# Add pattern rule(s) for creating compiled object code from C source.
$(foreach EXT,${C_SRC_EXTS},\
  $(eval $(call ADD_OBJECT_RULE,${EXT},$${COMPILE_C_CMDS})))

# Add pattern rule(s) for creating compiled object code from C++ source.
$(foreach EXT,${CXX_SRC_EXTS},\
  $(eval $(call ADD_OBJECT_RULE,${EXT},$${COMPILE_CXX_CMDS})))

endif
