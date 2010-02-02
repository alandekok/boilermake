# boilermake: A reusable, but flexible, boilerplate Makefile.
#
# Boilermake author: Dan Moulding <dmoulding@gmail.com> (2008)
#
# Major extensions
#  (multiple object targets, libtool, install, subdir Makefiles)
#         Alan DeKok <aland@freeradius.org>

# Caution: Don't edit this Makefile! Create your own main.mk and other
#          submakefiles, which will be included by this Makefile.
#          Only edit this if you need to modify boilermake's behavior (fix
#          bugs, add features, etc).

# Older versions of GNU Make lack capabilities needed by this system.
# Instead, running "make" returns "nothing to do".  In order to tell
# the user what really happened, we check the version of GNU make and
# return an error.
#
gnu_need := 3.81
gnu_ok := $(filter $(gnu_need),$(firstword $(sort $(MAKE_VERSION) $(gnu_need))))
ifeq ($(gnu_ok),)
$(error Your version of GNU Make is too old.  We need at least $(gnu_need))
endif

# If this ISN'T the top-level Makefile, then find out where it is
# and call it recursively.  This is the ONLY recursive use of "make"
# in the framework.  It exists ONLY to allow people to use "make"
# in a subdirectory.
#
ifneq "$(dir $(lastword $(MAKEFILE_LIST)))" "./"

root := $(patsubst ${CURDIR}/%,%,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))
subdir := $(subst ${root}/,,${PWD})

# Catch the common installation targets.
all clean targets ${ALL_TARGETS}:
	@$(MAKE) -C ${root} SUBDIR=${subdir} $@

else
BOILER_TOP := "yes"

# We are in the top-level directory.  Do non-recursive Make.
#

# Put these targets first, so that submakefiles can define their own
# targets without affecting the default target for "make".
.PHONY: all clean
all clean:

# Automatically set some variables if we're using libtool.  Object files
# are "foo.lo", not "foo.o".  Compilers are "libtool ... cc", not "cc".
#
ifeq "${LIBTOOL}" ""
OBJ_EXT = o
PROGRAM_CC = ${CC}
PROGRAM_CXX = ${CXX}
else
OBJ_EXT = lo
PROGRAM_CC = ${LIBTOOL} --mode=compile ${CC}
PROGRAM_CXX = ${LIBTOOL} --mode=compile ${CXX}
endif

ifeq "${INSTALL}" ""
install:
	@echo You need to define INSTALL in the top level Makefile.
	@exit 1
else
# Define this so other rules will use it, too.
install:
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
	@mkdir -p $$(dir $$@)
	${2}
endef

%.P: %.d
	@cp $< $@
	@sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	     -e '/^$$/ d' -e 's/$$/ :/' < $< >> $@
	@rm -f $<

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
	        $${${1}_OBJS} $${LDLIBS} $${${1}_PRLIBS} $${TGT_LDLIBS})
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
$(error Please define LIBTOOL and re-build)
endef

# ADD_INSTALL_RULE.* - Parameterized "functions" that adds a new
#   installation to the Makefile.  There should be one ADD_INSTALL_RULE
#   definition for each type of target that is used in the build.
#
#   New rules can be added by copying one of the existing ones, and
#   replacing the line containing $$(strip ...)
#

# ADD_INSTALL_RULE.exe - Parameterized "function" that adds a new rule
#   and phony target for installing an executable.
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.exe
    install: install_${1}
    .PHONY: install_${1}
    install_${1}: ${1}
	$$(strip $${INSTALL} -d 755 $${DESTDIR}/$${${1}_INSTALLDIR})
	$$(strip $${INSTALL} -m 755 ${1} $${DESTDIR}/$${${1}_INSTALLDIR})
	$${${1}_POSTINSTALL}
endef

# ADD_INSTALL_RULE.a - Parameterized "function" that adds a new rule
#   and phony target for installing a static library
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.a
    install: install_${1}
    .PHONY: install_${1}
    install_${1}: ${1}
	$$(strip $${INSTALL} -d 755 $${DESTDIR}/$${${1}_INSTALLDIR})
	$$(strip $${INSTALL} -m 755 ${1} $${DESTDIR}/$${${1}_INSTALLDIR})
	$${${1}_POSTINSTALL}
endef

#  If we're using libtool, re-define the target and installation
#  rules, as the linking rules are different.
#
ifneq "${LIBTOOL}" ""
define ADD_TARGET_RULE.la
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
            ${1}: TGT_LINKER = ${LIBTOOL} --mode=link -module $${CXX}
        else
            ${1}: TGT_LINKER = ${LIBTOOL} --mode=link -module $${CC}
        endif
    endif

    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $$(dir $$@)
	    $$(strip $${TGT_LINKER} -o ${1} $${LDFLAGS} $${TGT_LDFLAGS} \
	        $${${1}_OBJS} $${LDLIBS} $${TGT_LDLIBS})
	    $${TGT_POSTMAKE}
endef

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
            ${1}: TGT_LINKER = ${LIBTOOL} --mode=link $${CXX}
        else
            ${1}: TGT_LINKER = ${LIBTOOL} --mode=link $${CC}
        endif
    endif

    ${1}: $${${1}_OBJS} $${${1}_PREREQS}
	    @mkdir -p $$(dir $$@)
	    $$(strip $${TGT_LINKER} -o ${1} $${LDFLAGS} $${TGT_LDFLAGS} \
	        $${${1}_OBJS} $${LDLIBS} $${${1}_PRLIBS} $${TGT_LDLIBS})
	    $${TGT_POSTMAKE}
endef

# ADD_INSTALL_RULE.exe - Parameterized "function" that adds a new rule
#   and phony target for installing an executable.
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.exe
    install: install_${1}
    .PHONY: install_${1}
    install_${1}: ${1}
	$$(strip $${INSTALL} -d 755 $${DESTDIR}/$${${1}_INSTALLDIR})
	$$(strip $(LIBTOOL) --mode=install $${INSTALL} -m 755 ${1} $${DESTDIR}/$${${1}_INSTALLDIR})
	$${${1}_POSTINSTALL}
endef

# ADD_INSTALL_RULE.la - Parameterized "function" that adds a new rule
#   and phony target for installing a libtool library
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.la
    install: install_${1}
    .PHONY: install_${1}
    install_${1}: ${1}
	$$(strip $${INSTALL} -d 755 $${DESTDIR}/$${${1}_INSTALLDIR})
	$$(strip $(LIBTOOL) --mode=install $${INSTALL} -m 755 ${1} $${DESTDIR}/$${${1}_INSTALLDIR})
	$${${1}_POSTINSTALL}
endef

# end of libtool-specific target and install rules.
endif


# LIBTOOL_ENDINGS - Given a library ending in ".a" or ".so", replace that
#   extension with ".la".
#
define LIBTOOL_ENDINGS
$(patsubst %.a,%.la,$(patsubst %.so,%.la,${1}))
endef

#  Macro to return a full path for a file or directory.
#
define CANONICAL_PATH
$(patsubst ${CURDIR}/%,%,$(abspath ${1}))
endef

# COMPILE_C_CMDS - Commands for compiling C source code.
define COMPILE_C_CMDS
	$(strip ${PROGRAM_CC} -o $@ -c ${MD_FLAGS} ${CFLAGS} ${SRC_CFLAGS} ${INCDIRS} \
	    ${SRC_INCDIRS} ${SRC_DEFS} ${DEFS} $<)
endef

# COMPILE_CXX_CMDS - Commands for compiling C++ source code.
define COMPILE_CXX_CMDS
	$(strip ${PROGRAM_CXX} -o $@ -c ${MD_FLAGS} ${CXXFLAGS} ${SRC_CXXFLAGS} ${INCDIRS} \
	    ${SRC_INCDIRS} ${SRC_DEFS} ${DEFS} $<)
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
    TARGET := ..
    TGT_LDFLAGS :=
    TGT_LDLIBS :=
    TGT_LINKER :=
    TGT_POSTCLEAN :=
    TGT_POSTMAKE :=
    TGT_PREREQS :=
    TGT_POSTINSTALL :=
    TGT_INSTALLDIR := ..

    SOURCES :=
    SRC_CFLAGS :=
    SRC_CXXFLAGS :=
    SRC_DEFS :=
    SRC_INCDIRS :=

    SUBMAKEFILES :=

    # Ensure that valid values are set for BUILD_DIR and TARGET_DIR.
    ifeq "$$(strip $${BUILD_DIR})" ""
        BUILD_DIR := build
    endif
    ifeq "$$(strip $${TARGET_DIR})" ""
        TARGET_DIR := .
    endif

    # Define "local directory" and "build directory" targets for
    # the included submakefile.  The patsubst is there to remove
    # the trailing slash, which allows submakefiles to use
    #    $[b}/foo.o: ${d}/foo.c
    # instead of
    #    $[b}foo.o: ${d}foo.c
    #
    # If we didn't delete the trailing slash, Make could say that
    # the target "build/foo.o" isn't the same as the target "build//foo.o",
    # and refuse to re-build teh target for user-specificed dependencies.
    d := $(patsubst %/,%,$(dir ${1}))
    b := $(patsubst %/,%,${BUILD_DIR}/$(dir ${1}))

    include ${1}

    # Initialize internal local variables.
    OBJS :=

    # A directory stack is maintained so that the correct paths are used as we
    # recursively include all submakefiles. Get the makefile's directory and
    # push it onto the stack.
    DIR := $(call CANONICAL_PATH,$(dir ${1}))
    DIR_STACK := $$(call PUSH,$${DIR_STACK},$${DIR})

    # Determine which target this makefile's variables apply to. A stack is
    # used to keep track of which target is the "current" target as we
    # recursively include other submakefiles.
    #
    # In some cases, we do NOT want to build a target.  This is true
    # when a target has external dependencies that are not available
    # on a platform.  In that case, the submakefile should set TARGET
    # to be blank.  The target ".." is a special internal flag
    # indicating that the submakefile did NOT specify a target, and
    # it should instead be added to the sources of the previous target.
    ifeq "$$(strip $${TARGET})" ".."
        # The values defined by this makefile apply to the the "current" target
        # as determined by which target is at the top of the stack.

        # This may end up being "..", too.
        TGT := $$(strip $$(call PEEK,$${TGT_STACK}))

    else ifneq "$$(strip $${TARGET})" ""
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
        $${TGT}_POSTINSTALL := $${TGT_POSTINSTALL}

        # Figure out which target rule to use for building.
	TGT_SUFFIX := $$(suffix $${TGT})
        ifeq "$${TGT_SUFFIX}" ""
            # This rule is correct only when the framework is used
            # ONLY for building executables.  We need to fix it to
            # allow for building && installation of other kinds of files.
            TGT_SUFFIX := .exe

            ifeq "$${TGT_INSTALLDIR}" ".."
                TGT_INSTALLDIR := $${bindir}
            endif
        else 
            ifeq "$${TGT_INSTALLDIR}" ".."
                TGT_INSTALLDIR := $${libdir}
            endif
        endif

        $${TGT}_INSTALLDIR := $${TGT_INSTALLDIR}

        ifneq "${LIBTOOL}" ""
            TGT_PREREQS := $$(call LIBTOOL_ENDINGS,$${TGT_PREREQS})
        endif

        $${TGT}_PREREQS := $$(addprefix $${TARGET_DIR}/,$${TGT_PREREQS})
        $${TGT}_PRLIBS := $$(filter %.a %.so %.la,$${TGT_PREREQS})
        $${TGT}_DEPS :=
        $${TGT}_OBJS :=
        $${TGT}_SOURCES :=

    # TARGET was set to "", which means "don't build it".
    # So we set TGT to be the "don't build" flag.  This will carry
    # through to any children.
    else
        TGT := ..
    endif

    # If after all that, the current (or parent) target is "don't build",
    # then delete all of the sources so that it isn't built.
    ifeq "$$(strip $${TGT})" ".."
        SOURCES :=
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

        # add rules to build the target
        $$(eval $$(call ADD_TARGET_RULE$${TGT_SUFFIX},$${TGT}))

        ifneq "${INSTALL}" ""
            ifneq "$${$${TGT}_INSTALLDIR}" ""
                # add rules to install the target
                $$(eval $$(call ADD_INSTALL_RULE$${TGT_SUFFIX},$${TGT}))
            endif
        endif

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

# C compiler flags to do "make depend"
MD_FLAGS := -MD

# Include the main user-supplied submakefile. This also recursively includes
# all other user-supplied submakefiles.
$(eval $(call INCLUDE_SUBMAKEFILE,main.mk))

# Perform post-processing on global variables as needed.
DEFS := $(addprefix -D,${DEFS})
INCDIRS := $(addprefix -I,$(call CANONICAL_PATH,${INCDIRS}))

# Add pattern rule(s) for creating compiled object code from C source.
$(foreach EXT,${C_SRC_EXTS},\
  $(eval $(call ADD_OBJECT_RULE,${EXT},$${COMPILE_C_CMDS})))

# Add pattern rule(s) for creating compiled object code from C++ source.
$(foreach EXT,${CXX_SRC_EXTS},\
  $(eval $(call ADD_OBJECT_RULE,${EXT},$${COMPILE_CXX_CMDS})))

# Informational, so you can see which targets are available for building.
targets:
	@echo ${ALL_TGTS}

endif
