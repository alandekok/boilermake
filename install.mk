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

# INSTALL_NAME - Function to return the name of the file which should
#   be installed.  For non-libtool builds, it's just the name of the
#   file (executable or library).
#
#   If we're using libtool, INSTALL_NAME is already defined to point to
#   the RELINK version.  So don't re-define it here.
#
ifeq "${INSTALL_NAME}" ""
define INSTALL_NAME
${1}
endef
endif

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
    # Global install depends on ${1}
    install: $${${1}_INSTALLDIR}/$(notdir ${1})

    # Install executable ${1}
    $${${1}_INSTALLDIR}/$(notdir ${1}): $$(call INSTALL_NAME,${1})
	@mkdir -p $${${1}_INSTALLDIR}
	$${PROGRAM_INSTALL} -c -m 755 $$(call INSTALL_NAME,${1}) $${${1}_INSTALLDIR}/
	$${${1}_POSTINSTALL}

endef

# ADD_INSTALL_RULE.a - Parameterized "function" that adds a new rule
#   and phony target for installing a static library
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.a
    # Global install depends on ${1}
    install: $${${1}_INSTALLDIR}/$(notdir ${1})

    # Install static library ${1}
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
    # Global install depends on ${1}
    install: $${${1}_INSTALLDIR}/$(notdir ${1})

    # Install libtool library ${1}
    $${${1}_INSTALLDIR}/$(notdir ${1}): $$(call INSTALL_NAME,${1})
	@mkdir -p $${${1}_INSTALLDIR}
	$${PROGRAM_INSTALL} -c -m 755 $$(call INSTALL_NAME,${1}) $${${1}_INSTALLDIR}/
	$${${1}_POSTINSTALL}

endef

# ADD_INSTALL_RULE.man - Parameterized "function" that adds a new rule
#   and phony target for installing a "man" page.  It will take care of
#   installing it into the correct subdirectory of "man".
#
#   USE WITH EVAL
#
define ADD_INSTALL_RULE.man
    # Global install depends on ${1}
    install: ${2}/$(notdir ${1})

    # Install manual page ${1}
    ${2}/$(notdir ${1}): ${1}
	@mkdir -p ${2}/
	$${PROGRAM_INSTALL} -c -m 644 ${1} ${2}/

endef


# ADD_INSTALL_TARGET - Parameterized "function" that adds a new rule
#   which installs everything for the target.
#
#   USE WITH EVAL
#
define ADD_INSTALL_TARGET
    # Figure out which target rule to use for installation.
    ifeq "$${${1}_SUFFIX}" ".exe"
        ifeq "$${TGT_INSTALLDIR}" ".."
            TGT_INSTALLDIR := $${bindir}
        endif
    else 
        ifeq "$${TGT_INSTALLDIR}" ".."
            TGT_INSTALLDIR := $${libdir}
        endif
    endif

    ${1}_INSTALLDIR := $${DESTDIR}$${TGT_INSTALLDIR}

    # add rules to install the target
    ifneq "$${${1}_INSTALLDIR}" ""
        $$(eval $$(call ADD_INSTALL_RULE$${${1}_SUFFIX},${1}))
    endif

    # add rules to install the MAN pages.
    ifneq "$$(strip $${${1}_MAN})" ""
        ifeq "$${mandir}" ""
            $$(error You must define 'mandir' in order to be able to install MAN pages.)
        endif

        MAN := $$(call QUALIFY_PATH,$${DIR},$${MAN})
        MAN := $$(call CANONICAL_PATH,$${MAN})

        $$(foreach PAGE,$${MAN},\
            $$(eval $$(call ADD_INSTALL_RULE.man,$${PAGE},\
              $${DESTDIR}$${mandir}/man$$(subst .,,$$(suffix $${PAGE})))))
    endif
endef

.PHONY: install
install:

PROGRAM_INSTALL := ${INSTALL}

# Be nice to the user.  If there is no INSTALL program, then print out
# a helpful message.  Without this check, the "install" rules defined
# above would try to run a command-line with a blank INSTALL, and give
# some inscrutable error.
ifeq "${INSTALL}" ""
install: install_ERROR

.PHONY: install_ERROR
install_ERROR:
	@echo Please define INSTALL in order to enable the installation rules.
	@exit 1
endif
