TARGET := talk

TGT_LDFLAGS := -L.
TGT_LDLIBS  := -lanimals -lplants
TGT_PREREQS := libanimals.a libplants.a

SOURCES := talk.cc

SRC_INCDIRS := \
    animals \
    animals/cat \
    animals/dog \
    animals/dog/chihuahua \
    animals/mouse \
    plants \
    plants/tree
