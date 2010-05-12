# We don't use boilermake here because we want to run the test-app
# as a self-contained system that runs boilermake.
#

all: run-tests

test-app/talk:
	${MAKE} -C test-app/

run-tests: test-app/talk
	./test-app/talk > found.txt
	diff expected.txt found.txt
	${MAKE} -C test-app/ DESTDIR=`pwd`/R bindir=/usr/local/bin libdir=/usr/local/lib INSTALL=`pwd`/install-sh install
	find R/* -print > found-install.txt
	diff expected-install.txt found-install.txt
	./test-app/talk > found.txt
	diff expected.txt found.txt
	${MAKE} -C test-app/ clean

clean: clean.local

clean.local:
	${MAKE} -C test-app/ clean
	rm -rf ./R *~
