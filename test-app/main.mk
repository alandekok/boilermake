CXXFLAGS := -g -O0 -Wall -pipe

SUBMAKEFILES := talk.mk animals/animals.mk plants/plants.mk

# Common definitions for installation
INSTALL	 := $(shell which install)
prefix   := /usr/local
bindir   := ${prefix}/bin
libdir   := ${prefix}/lib
