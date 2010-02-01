CXXFLAGS := -g -O0 -Wall -pipe
INCDIRS  := animals
LDFLAGS  := -L.

SUBMAKEFILES := talk.mk

#
install:
	@echo Install!
