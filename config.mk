# CHECK_HEADER_RULE - Parameterized "function" that checks for the
#   existence (or not) of a header.  It creates a C definition for the
#   header file, and a "make" definition for the same thing.
#
#   USE WITH EVAL
#
define CHECK_HEADER_RULE
    ALL_CHECK_HEADERS += ${1}
    ALL_CONFIG_H += $${BUILD_DIR}/make/include/ac_${2}.h

    $${BUILD_DIR}/make/src/${2}.c:
	@$(strip mkdir -p $$(dir $$@))
	@echo "#include <${1}>" > $$@

    $${BUILD_DIR}/make/include/ac_${2}.h: $${BUILD_DIR}/make/src/${2}.c
	@$(strip mkdir -p $$(dir $$@))
	@echo -n 'checking for ${1}... '
	@if $${CC} $${CFLAGS} -c $${BUILD_DIR}/make/src/${2}.c -o $${BUILD_DIR}/make/include/${2}.o > /dev/null 2>&1; then \
	    echo yes; \
	    echo "#define HAVE_$(shell echo ${1} | tr 'a-z' 'A-Z' | tr '/.-' '___') 1" > $$@; \
	else \
	    echo no; \
	    touch $$@; \
	fi
	@rm -f $${BUILD_DIR}/make/include/${2}.o

    $${BUILD_DIR}/make/defs/lib${2}.mk: $${BUILD_DIR}/make/include/ac_${2}.h
	@$(strip mkdir -p $$(dir $$@))
	@sed -e 's/#define /AC_/' -e 's/ 1/ = 1/' < $$< > $$@

    # include the generated Makefile, so that it is built *before*
    # any targets, and so that we have the resulting definitions during
    # the rest of the build phase.
    -include $${BUILD_DIR}/make/defs/${2}.mk

    $${BUILD_DIR}/make/include/config.h: $${BUILD_DIR}/make/include/ac_${2}.h

    $${BUILD_DIR}/make/defs/config.mk: $${BUILD_DIR}/make/defs/${2}.mk

endef


# CHECK_LIB_RULE - Parameterized "function" that checks for the
#   existence (or not) of a library.  Arguments are "function lib"
#
#   USE WITH EVAL
#
define CHECK_LIBRARY_RULE
    ALL_CHECK_LIBS += ${1}
    ALL_CONFIG_H += $${BUILD_DIR}/make/include/ac_lib${1}.h

    # FIXME: this should depend on all of the Makefiles.
    $${BUILD_DIR}/make/test/lib${1}.c:
	@$(strip mkdir -p $$(dir $$@))
	@echo 'void ${2}(); int main () { ${2}(); return 0;}' > $$@

    $${BUILD_DIR}/make/include/ac_lib${1}.h: $${BUILD_DIR}/make/test/lib${1}.c
	@$(strip mkdir -p $$(dir $$@))
	@echo -n 'checking for ${2} in -l${1}... '
	@if $${CC} $${CFLAGS} -o $${BUILD_DIR}/make/include/lib${1} $${CFLAGS} $${BUILD_DIR}/make/test/lib${1}.c -l${1} > /dev/null 2>&1; then \
	    echo yes; \
	    echo "#define HAVE_LIB$(shell echo ${1} | tr 'a-z' 'A-Z' | tr '/.-' '___') 1" > $$@; \
	else \
	    echo no; \
	    touch $$@; \
	fi
	@rm -f $${BUILD_DIR}/make/include/lib${1}

    $${BUILD_DIR}/make/defs/lib${1}.mk: $${BUILD_DIR}/make/include/ac_lib${1}.h
	@$(strip mkdir -p $$(dir $$@))
	@sed -e 's/#define /AC_/' -e 's/ 1/ = 1/' < $$< > $$@
	@echo '${1}_LDFLAGS := -l${1}' >> $$@

    # include the generated Makefile, so that it is built *before*
    # any targets, and so that we have the resulting definitions during
    # the rest of the build phase.
    -include $${BUILD_DIR}/make/defs/lib${1}.mk

    $${BUILD_DIR}/make/include/config.h: $${BUILD_DIR}/make/include/ac_lib${1}.h

    $${BUILD_DIR}/make/defs/config.mk: $${BUILD_DIR}/make/defs/lib${1}.mk

endef

# Empty target so that we can build config.h even if there are
# no configure checks.
${BUILD_DIR}/make/include/empty.h:
	@mkdir -p $(dir $@)
	@touch $@

# Global include configuration depends on all of the config files
${BUILD_DIR}/make/include/config.h: ${BUILD_DIR}/make/include/empty.h
	@mkdir -p $(dir $@)
	@cat $^ > $@

# Global make configuration depends on all of the config files
${BUILD_DIR}/make/defs/config.mk:
	@cat $^ > $@

define ADD_CONFIG_DEP_H
    $${BUILD_DIR}/make/include/${1}_config.h: $${BUILD_DIR}/make/include/ac_${2}.h

    $${BUILD_DIR}/make/defs/${1}_config.mk: $${BUILD_DIR}/make/defs/${2}.mk

endef

define ADD_CONFIG_DEP_LIB
    $${BUILD_DIR}/make/include/${1}_config.h: $${BUILD_DIR}/make/include/ac_lib${2}.h

    $${BUILD_DIR}/make/defs/${1}_config.mk: $${BUILD_DIR}/make/defs/lib${2}.mk

endef

# ADD_TARGET_CONFIG - Parameterized "function" that checks for the
#   existence (or not) of a library.  Arguments are "function lib"
#
#   FIXME: check if there's already a rule for the header/lib.  If so,
#   don't regenerate the rule for it.
#
#   USE WITH EVAL
#
define ADD_TARGET_CONFIG
    # check the headers
    $$(foreach H,$${${1}_CHECK_HEADERS},\
        $$(eval $$(call CHECK_HEADER_RULE,$${H},$$(subst /,_,$$(subst .,_,$${H})))))

    # check the libraries
    $$(foreach L,$${${1}_CHECK_LIBS},\
        $$(eval $$(call CHECK_LIBRARY_RULE,$${L},$${AC_CHECK_FUNC_LIB_$${L}})))

    # Create the $${TGT}_config.h file
    $$(foreach H,$${${1}_CHECK_HEADERS},\
        $$(eval $$(call ADD_CONFIG_DEP_H,$$(notdir $$(basename $${TGT})),$$(subst /,_,$$(subst .,_,$${H})))))

    # check the libraries
    $$(foreach L,$${${1}_CHECK_LIBS},\
        $$(eval $$(call ADD_CONFIG_DEP_LIB,$${TGT},$${L})))

    # ensure that the object files depend on the config include file.
    # FIXME: make the target object depend only on the config files
    # generated for this target...
    $${${1}_OBJS}: $${BUILD_DIR}/make/include/config.h 

    $${BUILD_DIR}/make/include/${1}_config.h:
	@cat $$^ > $$@

    $${BUILD_DIR}/make/defs/${1}_config.mk:
	@cat $$^ > $$@

endef

# Tell the global build system that we need to look at headers
# in the build directory.
INCDIRS += ${BUILD_DIR}/make/include
