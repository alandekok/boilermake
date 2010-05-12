# We don't use boilermake here because we want to run the test-app
# as a self-contained system that runs boilermake.
#

all: run-tests

test-app/talk:
	${MAKE} -C test-app/

run-tests: test-app/talk
	./test-app/talk > found.txt
	diff expected.txt found.txt
	${MAKE} -C test-app/ clean
