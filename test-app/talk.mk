TARGET := talk

# This automatically sets the correct linker flags to grab these files.
TGT_PREREQS := libanimals.a libplants.a

SOURCES := talk.cc

MAN := talk.1

SRC_INCDIRS := \
    animals \
    animals/cat \
    animals/dog \
    animals/dog/chihuahua \
    animals/mouse \
    plants \
    plants/tree
