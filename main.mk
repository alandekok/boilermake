# We don't use boilermake here because we want to run the test-app
# as a self-contained system that runs boilermake.
#

all: run-tests

.PHONY: run-tests
run-tests:
	${MAKE} clean
	${MAKE} -C test-app/
	./test-app/talk > found.txt
	diff expected.txt found.txt
	${MAKE} -C test-app/ DESTDIR=`pwd`/R bindir=/usr/local/bin libdir=/usr/local/lib INSTALL=`pwd`/install-sh install
	find R/* -print > found-install.txt
	diff expected-install.txt found-install.txt
	./test-app/talk > found.txt
	diff expected.txt found.txt
	${MAKE} clean
	rm -rf R/
	${MAKE} -C test-app/ LIBTOOL=`pwd`/jlibtool DESTDIR=`pwd`/R bindir=/usr/local/bin libdir=/usr/local/lib INSTALL=`pwd`/install-sh all
	./test-app/talk > found.txt
	diff expected.txt found.txt
	${MAKE} -C test-app/ LIBTOOL=`pwd`/jlibtool DESTDIR=`pwd`/R bindir=/usr/local/bin libdir=/usr/local/lib INSTALL=`pwd`/install-sh install
# don't do "find", as we have *.la files installed, rather than *.a
	./test-app/talk > found.txt
	diff expected.txt found.txt
	${MAKE} clean
	rm -rf R found found-install.txt

clean: clean.local

clean.local:
	${MAKE} -C test-app/ clean
	${MAKE} -C test-app/ LIBTOOL=x clean
	rm -rf ./R *~ found.txt found-install.txt
