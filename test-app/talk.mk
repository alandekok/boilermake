TARGET := talk

TGT_LDLIBS := 
TGT_PREREQS := libanimals.a

SOURCES := talk.cc

SRC_INCDIRS := \
    animals/cat \
    animals/dog \
    animals/dog/chihuahua \
    animals/mouse

SUBMAKEFILES := animals/animals.mk
